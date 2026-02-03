# 👔 Armario Virtual

![Flutter](https://img.shields.io/badge/Flutter-3.19-%2302569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Core-%23FFCA28?logo=firebase)
![Google Cloud](https://img.shields.io/badge/Google_Cloud-Vision%20%26%20Translate-%234285F4?logo=google-cloud)
![Python](https://img.shields.io/badge/Cloud_Functions-Python_3.11-%233776AB?logo=python)

**Armario Virtual** es una aplicación móvil inteligente desarrollada en Flutter que digitaliza tu vestuario personal. No solo almacena tus prendas, sino que utiliza **Inteligencia Artificial** en la nube para categorizarlas, detectar colores y sugerirte productos similares, revolucionando la forma en que gestionas tu estilo.

## 🚀 Funcionalidades Principales

### 🧥 Gestión de Inventario con IA
* **Procesamiento de Imágenes:** Al subir una foto, la app recorta automáticamente los bordes transparentes y optimiza el tamaño utilizando **Dart Isolates** para no bloquear la interfaz.
* **Eliminación de Fondo:** Integración con API externa (via Cloud Functions) para dejar tus prendas limpias y profesionales visualmente.
* **Etiquetado Automático (Auto-Tagging):** La app detecta qué prenda es (ej. "Camiseta", "Vaqueros") y sus colores predominantes automáticamente.

### 🛍️ Smart Shopping & Discovery
* **Buscador de Similares:** ¿Te gustan tus zapatos? La app utiliza los tags generados para buscar productos similares en la web en tiempo real.
* **Traducción Automática:** Las etiquetas detectadas por la IA en inglés se traducen automáticamente al español para una mejor experiencia de usuario.

### 📅 Fitting Room (Probador Virtual)
* **Compositor de Outfits:** Interfaz Drag & Drop para combinar parte superior, inferior y calzado.
* **Validación de Estilo:** Sistema que asegura que selecciones una prenda de cada categoría esencial antes de guardar.

---

## ☁️ Arquitectura Cloud (Google Cloud Platform & Firebase)

El núcleo de la inteligencia de *Armario Virtual* reside en una arquitectura *Serverless* robusta desplegada en **GCP (Región: europe-west1)**.

### 🧠 Cerebro en la Nube: Cloud Functions (Python Gen 2)
El backend no es solo una base de datos; ejecuta lógica compleja de IA mediante funciones en la nube:

1.  **Visión Computacional (`get_ai_tags_for_garment`):**
    * Utiliza **Google Cloud Vision API** para analizar la imagen de la prenda.
    * Extrae etiquetas (Labels) con un nivel de confianza > 70%.
    * Analiza las propiedades de la imagen para extraer los colores dominantes en RGB.

2.  **Procesamiento de Lenguaje (`Google Translation API`):**
    * Las etiquetas obtenidas por la Vision API se pasan por la **Google Cloud Translation API** para convertirlas del inglés al español, filtrando palabras irrelevantes (ej. "textil", "producto") mediante una lista de exclusión personalizada.

3.  **Motor de Búsqueda (`find_similar_products`):**
    * Utiliza **Google Custom Search API** (JSON API) para realizar búsquedas visuales en la web basadas en las etiquetas de la prenda, devolviendo enlaces de compra o referencias visuales.

### 🛡️ Seguridad y Datos
* **Firebase Auth & Identity Platform:** Gestión de usuarios mediante Correo/Contraseña y **Google Sign-In**.
* **Firebase App Check:** Protección contra tráfico abusivo utilizando *Play Integrity* en Android.
* **Secret Manager:** Las claves de API (Custom Search, Remove.bg) se gestionan de forma segura mediante secretos de Cloud Functions, sin exponerlas en el código.
* **Cloud Firestore:** Base de datos NoSQL optimizada para lectura en tiempo real.
* **Cloud Storage:** Almacenamiento de activos multimedia con estructura de carpetas por usuario (`garment_images/{userId}/`).

---

## 🛠️ Stack Tecnológico

* **Frontend:** Flutter (Dart).
* **Gestión de Estado:** `setState` local y Servicios desacoplados (`GarmentService`, `OutfitService`).
* **Backend:** Firebase (BaaS) + Google Cloud Functions (Python).
* **Librerías Clave:**
    * `google_sign_in` & `firebase_auth`: Autenticación.
    * `image_picker` & `image_cropper`: Captura y edición.
    * `flutter_image_compress` (implementación propia con `image`): Optimización.

---

## 🔧 Instalación y Despliegue

### Requisitos
* Flutter SDK 3.x
* Cuenta de Google Cloud con facturación habilitada (para Vision/Translate APIs).
* Cuenta de Remove.bg (para la API Key).

### Configuración
1.  **Clonar el proyecto:**
    ```bash
    git clone [https://github.com/aleramiirez/armario-virtual.git](https://github.com/aleramiirez/armario-virtual.git)
    ```
2.  **Configurar Firebase:**
    * Instala `flutterfire_cli`.
    * Ejecuta `flutterfire configure` para generar `firebase_options.dart`.
3.  **Desplegar Cloud Functions:**
    * Navega a la carpeta `functions/`.
    * Configura tus secretos en GCP:
        ```bash
        firebase functions:secrets:set CUSTOM_SEARCH_API_KEY
        firebase functions:secrets:set REMOVE_BG_API_KEY
        ```
    * Despliega:
        ```bash
        firebase deploy --only functions
        ```
4.  **Ejecutar la App:**
    ```bash
    flutter run
    ```

---

## 🤝 Contribución

Las contribuciones son bienvenidas. Por favor, abre un *issue* para discutir cambios mayores antes de enviar un *Pull Request*.

---

<p align="center">
  Desarrollado por <b>Alejandro Ramírez</b>
</p>
