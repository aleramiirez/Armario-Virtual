from firebase_functions import https_fn, options
from firebase_admin import initialize_app, firestore
from google.cloud import vision
import logging

initialize_app()
options.set_global_options(region="europe-west1")

WORDS_TO_EXCLUDE = {
    "textile", "fabric", "material", "product", "sleeve", "pattern",
    "design", "clothing", "outerwear", "fashion", "style", "font", "logo",
    "fashion design",
}

@https_fn.on_call()
def get_ai_tags_for_garment(req: https_fn.Request) -> https_fn.Response:
    """
    Recibe el ID de una prenda, la analiza con la API de Vision y devuelve las etiquetas.
    """
    
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
            {"type_": vision.Feature.Type.LABEL_DETECTION, "max_results": 10},
            {"type_": vision.Feature.Type.IMAGE_PROPERTIES, "max_results": 5},
        ],
    })

    processed_labels = {
        label.description.lower()
        for label in response.label_annotations
        if label.score > 0.75 and label.description.lower() not in WORDS_TO_EXCLUDE
    }
        
    processed_colors = []
    dominant_colors = response.image_properties_annotation.dominant_colors.colors
    for color_info in dominant_colors:
        if color_info.pixel_fraction > 0.10:
            c = color_info.color
            rgb_string = f"{int(c.red)}_{int(c.green)}_{int(c.blue)}"
            processed_colors.append(rgb_string)

    all_new_tags = list(processed_labels) + processed_colors
    logging.info(f"Etiquetas procesadas para {garment_id}: {all_new_tags}")

    if all_new_tags:
        garment_ref.update({
            "aiLabels": firestore.ArrayUnion(list(processed_labels)),
            "aiColors": firestore.ArrayUnion(processed_colors),
        })

    return {
        "aiLabels": list(processed_labels),
        "aiColors": processed_colors,
    }