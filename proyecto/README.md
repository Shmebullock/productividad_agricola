\# Productividad agrícola en Ecuador



\## 1. Descripción del proyecto



Este repositorio contiene los archivos, bases de datos, scripts y resultados correspondientes a una investigación sobre la productividad agrícola en Ecuador, utilizando información estadística del Instituto Nacional de Estadística y Censos (INEC).



El proyecto contempla el procesamiento y limpieza de bases de datos, el análisis descriptivo de las variables agrícolas y la aplicación de métodos estadísticos para estudiar las relaciones entre las características de las unidades productivas y la productividad agrícola.



El procesamiento y análisis de la información se desarrolla mediante R y RStudio, mientras que Quarto se utiliza para organizar y presentar los resultados de manera reproducible.



\## 2. Requisitos para ejecutar el proyecto



Antes de comenzar, es necesario contar con los siguientes programas:



\- \*\*R:\*\* lenguaje de programación utilizado para el procesamiento y análisis estadístico.

\- \*\*RStudio:\*\* entorno de desarrollo para ejecutar los scripts de R.

\- \*\*Quarto:\*\* herramienta para generar documentos e informes reproducibles.

\- \*\*Git:\*\* herramienta para controlar las versiones del proyecto y sincronizar los cambios con GitHub.



Los principales paquetes utilizados en R son:



```r

install.packages(c("readr", "dplyr", "stringr", "readxl"))

```



Una vez instalados, deben cargarse al inicio de los scripts correspondientes:



```r

library(readr)

library(dplyr)

library(stringr)

library(readxl)

```



Los paquetes solo necesitan instalarse una vez por entorno de R, pero deben cargarse en cada nueva sesión en la que se utilicen.



\## 3. Estructura del proyecto



El repositorio se encuentra organizado de la siguiente manera:



```text

productividad\_agricola/

│

├── 01\_data\_cruda/

│   └── Bases de datos originales del INEC

│

├── 02\_datos\_procesados/

│   └── Bases de datos limpias y procesadas

│

├── 03\_scripts/

│   └── Scripts de R para limpieza y análisis

│

├── 04\_graficos/

│   └── Gráficos y visualizaciones

│

├── 05\_resultados/

│   └── Tablas, estadísticas y resultados

│

├── 06\_referencias/

│   └── Bibliografía y documentos de apoyo

│

├── 07\_manuscrito/

│   └── Documentos de la investigación

│

├── \_quarto.yml

├── index.qmd

├── marco\_teorico.qmd

├── productividad\_agricola.Rproj

└── renv.lock

```



Las carpetas `.quarto`, `\_book` y `renv` pueden generarse o utilizarse como parte del entorno de trabajo y la compilación del proyecto.



\## 4. Instrucciones para abrir el proyecto



\*\*IMPORTANTE: Siempre se debe abrir primero el archivo `productividad\_agricola.Rproj`.\*\*



Este archivo permite iniciar RStudio utilizando la carpeta principal del proyecto como directorio de trabajo.



Pasos para comenzar:



1\. Descargar o clonar el repositorio de GitHub.

2\. Abrir la carpeta principal `productividad\_agricola`.

3\. Hacer doble clic en el archivo `productividad\_agricola.Rproj`.

4\. Esperar a que RStudio abra el proyecto.

5\. Abrir los scripts correspondientes desde la carpeta `03\_scripts`.

6\. Cargar los paquetes necesarios y ejecutar el código.



Para verificar que el directorio de trabajo es correcto, ejecutar:



```r

getwd()

```



La ruta debe terminar en `productividad\_agricola`.



También se puede comprobar que R reconoce las carpetas:



```r

dir.exists("01\_data\_cruda")

dir.exists("02\_datos\_procesados")

dir.exists("03\_scripts")

```



Las tres instrucciones deben devolver `TRUE`.



\*\*No se recomienda utilizar `setwd()` dentro de los scripts\*\*, ya que las rutas locales pueden ser diferentes en las computadoras de los colaboradores.



\## 5. Ejecución de los scripts



Los scripts deben ejecutarse respetando el orden lógico del procesamiento de información:



1\. \*\*Preparación y limpieza:\*\* importar las bases originales del INEC desde `01\_data\_cruda`, revisar las variables y realizar la depuración correspondiente.

2\. \*\*Generación de bases procesadas:\*\* guardar los archivos limpios en `02\_datos\_procesados`.

3\. \*\*Análisis descriptivo:\*\* elaborar estadísticas, tablas y gráficos para caracterizar la información.

4\. \*\*Análisis estadístico:\*\* ejecutar los modelos y procedimientos definidos en la metodología de la investigación.

5\. \*\*Presentación de resultados:\*\* guardar las tablas en `05\_resultados`, los gráficos en `04\_graficos` y actualizar los documentos de Quarto.



Los scripts deben trabajar con rutas relativas a la carpeta principal del proyecto.



Por ejemplo, para importar una base:



```r

datos <- readr::read\_csv(

&#x20; "01\_data\_cruda/INEC\_ctnac\_BD\_2025.csv"

)

```



Este es un ejemplo de ruta; la función de lectura y sus parámetros deben ajustarse al formato del archivo.



Para guardar una base procesada:



```r

readr::write\_csv(

&#x20; datos,

&#x20; "02\_datos\_procesados/datos\_limpios.csv"

)

```



Se recomienda no modificar directamente las bases originales almacenadas en `01\_data\_cruda`.



\## 6. Uso de Quarto



El proyecto utiliza Quarto Book para organizar la documentación de la investigación.



El archivo `\_quarto.yml` contiene la configuración general del libro, mientras que los archivos `.qmd` contienen sus diferentes secciones.



Para garantizar que Quarto ejecute el código desde la carpeta principal, se recomienda incluir dentro de la configuración existente:



```yaml

project:

&#x20; type: book

&#x20; execute-dir: project

```



Para generar el libro desde la terminal, ubicada en la raíz del proyecto, se puede utilizar:



```bash

quarto render

```



El resultado se genera normalmente en la carpeta `\_book`.



\## 7. Colaboración y actualización en GitHub



Para trabajar de manera colaborativa, cada integrante debe tener acceso al repositorio y contar con una copia local del proyecto.



Antes de comenzar una sesión de trabajo, se recomienda descargar los cambios recientes:



```bash

git pull origin main

```



Una vez realizadas las modificaciones, comprobar los archivos modificados:



```bash

git status

```



Para registrar y subir los cambios:



```bash

git add .

git commit -m "Actualizacion del proyecto"

git push origin main

```



Se recomienda utilizar mensajes de confirmación que describan los cambios realizados y evitar subir archivos temporales, información confidencial o archivos de gran tamaño innecesarios.



En caso de conflictos al sincronizar, estos deben resolverse antes de volver a subir los cambios. No se recomienda utilizar `git push --force` en el trabajo colaborativo.



\## 8. Indicaciones adicionales



\- Mantener los nombres originales de las variables del INEC durante la importación, salvo las transformaciones documentadas que requiera el análisis.

\- Conservar las bases originales sin modificaciones para garantizar la trazabilidad de los datos.

\- Guardar las bases limpias únicamente en la carpeta destinada a datos procesados.

\- Incorporar comentarios en los scripts para explicar las principales operaciones de limpieza, transformación y análisis.

\- Evitar rutas absolutas y referencias a carpetas personales.

\- No duplicar innecesariamente archivos ni generar múltiples versiones con nombres ambiguos.

\- Verificar que los scripts funcionen correctamente antes de subirlos al repositorio.

\- Documentar los criterios metodológicos utilizados para construir indicadores, seleccionar observaciones y estimar modelos.

\- Utilizar `renv.lock` para facilitar la reproducción del entorno de paquetes, cuando corresponda.

\- Coordinar las modificaciones entre colaboradores para evitar conflictos de versiones.



\## 9. Reproducibilidad de la investigación



La organización del repositorio busca facilitar la reproducción de los análisis, desde la importación de las bases originales hasta la generación de los resultados finales.



Para reproducir el procesamiento, se debe abrir el archivo `.Rproj`, verificar la disponibilidad de las bases originales, restaurar o instalar las dependencias necesarias y ejecutar los scripts en el orden correspondiente.



Los procedimientos de limpieza, transformación y análisis deben quedar documentados de manera que otros investigadores puedan revisar y reproducir los resultados utilizando las mismas fuentes de información y criterios metodológicos.



\---



\*\*Proyecto:\*\* Productividad agrícola en Ecuador  

\*\*Fuente principal de información:\*\* Instituto Nacional de Estadística y Censos (INEC).  

\*\*Herramientas:\*\* R, RStudio, Quarto, Git y GitHub.  

\*\*Repositorio:\*\* https://github.com/Shmebullock/productividad\_agricola



