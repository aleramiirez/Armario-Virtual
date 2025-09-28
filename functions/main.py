import os
from firebase_functions import https_fn, options
import firebase_admin
from firebase_admin import initialize_app, firestore
from google.cloud import vision
from google.cloud import translate_v2 as translate
from googleapiclient.discovery import build
import logging
import requests
import base64

# --- INICIALIZACIÓN DE FIREBASE Y SERVICIOS ---
if not firebase_admin._apps:
    initialize_app()
    
options.set_global_options(region="europe-west1")

# Instanciamos el cliente de traducción una vez
translate_client = None

# --- LISTA DE PALABRAS A EXCLUIR ---
WORDS_TO_EXCLUDE_ES = {
    "textil", "tela", "material", "producto", "manga", "patrón", "estampado",
    "diseño", "ropa", "prenda", "vestimenta", "moda", "estilo", "fuente",
    "logo", "logotipo", "diseño de moda", "boquilla", "calle", "ciudad",
    "fotografía", "instantánea", "pierna", "calzado", "pantalones cortos de tabla",
}

# --- FUNCIÓN PARA OBTENER ETIQUETAS DE IA ---
@https_fn.on_call(secrets=["CUSTOM_SEARCH_API_KEY"])
def get_ai_tags_for_garment(req: https_fn.Request) -> https_fn.Response:
    global translate_client
    if translate_client is None:
        translate_client = translate.Client()
        
    if req.auth is None:
        raise https_fn.HttpsError(code="unauthenticated", message="La función debe ser llamada por un usuario autenticado.")

    user_id = req.auth.uid
    garment_id = req.data.get("garmentId")
    if not garment_id:
        raise https_fn.HttpsError(code="invalid-argument", message="Falta el parámetro 'garmentId'.")

    db = firestore.client()
    garment_ref = db.collection("users").document(user_id).collection("garments").document(garment_id)
    
    try:
        garment_doc = garment_ref.get()
        if not garment_doc.exists:
            raise https_fn.HttpsError(code="not-found", message="La prenda no existe.")
        image_url = garment_doc.to_dict().get("imageUrl")
        if not image_url:
            raise https_fn.HttpsError(code="not-found", message="La prenda no tiene una URL de imagen.")
    except Exception as e:
        logging.error(f"Error al leer de Firestore: {e}")
        raise https_fn.HttpsError(code="internal", message="Error al obtener los datos de la prenda.")

    client = vision.ImageAnnotatorClient()
    image = vision.Image()
    image.source.image_uri = image_url

    response = client.annotate_image({
        "image": image,
        "features": [
            {"type_": vision.Feature.Type.LABEL_DETECTION, "max_results": 20},
            {"type_": vision.Feature.Type.IMAGE_PROPERTIES, "max_results": 5},
        ],
    })

    english_labels = [
        label.description
        for label in response.label_annotations
        if label.score > 0.70
    ]

    translated_labels_result = translate_client.translate(english_labels, target_language='es', source_language='en')
    
    processed_labels = {
        translation['translatedText'].lower()
        for translation in translated_labels_result
        if translation['translatedText'].lower() not in WORDS_TO_EXCLUDE_ES
    }

    # (La lógica de los colores no cambia)
    processed_colors = []
    dominant_colors = response.image_properties_annotation.dominant_colors.colors
    for color_info in dominant_colors:
        if color_info.pixel_fraction > 0.10:
            c = color_info.color
            rgb_string = f"{int(c.red)}_{int(c.green)}_{int(c.blue)}"
            processed_colors.append(rgb_string)

    # El resto del proceso sigue igual, pero ahora 'aiLabels' se guarda en español
    if processed_labels or processed_colors:
        garment_ref.update({
            "aiLabels": firestore.ArrayUnion(list(processed_labels)),
            "aiColors": firestore.ArrayUnion(processed_colors),
        })

    # La función ahora devuelve las etiquetas ya traducidas y filtradas
    return {
        "aiLabels": list(processed_labels),
        "aiColors": processed_colors,
    }

# --- FUNCIÓN PARA BUSCAR PRODUCTOS SIMILARES ---
@https_fn.on_call(secrets=["CUSTOM_SEARCH_API_KEY"])
def find_similar_products(req: https_fn.Request) -> https_fn.Response:
    global translate_client
    if translate_client is None:
        translate_client = translate.Client()
        
    tags = req.data.get("tags")
    if not tags:
        raise https_fn.HttpsError(code="invalid-argument", message="Faltan las etiquetas.")
    
    # Traducimos las etiquetas al inglés para la búsqueda, que es más efectiva
    try:
        translated_tags_result = translate_client.translate(tags[:5], target_language='en', source_language='es')
        english_tags = [t['translatedText'] for t in translated_tags_result]
        query = " ".join(english_tags)
    except Exception as e:
        logging.error(f"Error al traducir para búsqueda: {e}")
        query = " ".join(tags[:5]) # Si falla la traducción, busca en español

    logging.info(f"Buscando productos para la consulta: '{query}'")
    
    search_engine_id = "a4ef255231839499a"
    api_key_value = os.environ.get("CUSTOM_SEARCH_API_KEY") 

    try:
        service = build("customsearch", "v1", developerKey=api_key_value)
        result = (
            service.cse()
            .list(q=query, cx=search_engine_id, searchType="image", num=10)
            .execute()
        )
    except Exception as e:
        logging.error(f"Error al llamar al API de búsqueda: {e}")
        raise https_fn.HttpsError(code="internal", message="Error al realizar la búsqueda.")

    products = []
    if "items" in result:
        for item in result["items"]:
            products.append({
                "title": item.get("title"),
                "link": item.get("image", {}).get("contextLink"),
                "imageUrl": item.get("link"),
            })
    
    return {"products": products}

# --- FUNCIÓN PARA QUITAR EL FONDO DE IMAGEN ---
@https_fn.on_call(secrets=["REMOVE_BG_API_KEY"])
def remove_background_from_image(req: https_fn.Request) -> https_fn.Response:
    image_base64 = req.data.get("imageBase64")
    if not image_base64:
        raise https_fn.HttpsError(code="invalid-argument", message="Falta el string Base64 de la imagen.")
    try:
        image_bytes = base64.b64decode(image_base64)
    except Exception as e:
        logging.error(f"Error al decodificar Base64: {e}")
        raise https_fn.HttpsError(code="invalid-argument", message="El string Base64 no es válido.")
    api_key_value = os.environ.get("REMOVE_BG_API_KEY")
    try:
        response = requests.post(
            "https://api.remove.bg/v1.0/removebg",
            files={"image_file": image_bytes},
            data={"size": "auto"},
            headers={"X-Api-Key": api_key_value},
        )
        response.raise_for_status()
        processed_base64 = base64.b64encode(response.content).decode('utf-8')
        return {"imageBase64": processed_base64}
    except requests.exceptions.RequestException as e:
        logging.error(f"Error al llamar a la API de remove.bg: {e}")
        raise https_fn.HttpsError(code="internal", message="Error al procesar la imagen.")