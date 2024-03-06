Sebastian Navia
* En Main.tf se definen recursos en la nube de Microsoft Azure utilizando Terraform, específicamente para implementar una aplicación de funciones.
* En variables.tf se han definido dos variables en Terraform: "name_function" para el nombre de la función con tipo string y "location" para la ubicación por defecto en "West Europe".
* En output: Aquí se  declara un bloque de salida (output) en Terraform, donde se expone la URL de invocación de la función dentro de la aplicación de funciones que se han definido.

- Enlazamos nuestra cuenta de azure con az login:
![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/1988adab-3665-479f-a161-a2cca84ba475)

- Luego, tenemos que correr el comando “terraform init” el cual permite inicializar nuestro entorno
![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/25b58ac4-14d9-4aa5-a178-7a334757e176)

- Proceder a escribir el comando “terraform validate” para validar que nuestra sintaxis.
![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/9ea9ea35-bee3-4c6e-8dcc-65b6ccff6d8b)

-Luego, “terraform plan” este comando lo que nos permitirá es echar un vistazo a la infraestructura que estamos creando.
![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/c4723ac3-adb9-4613-a57f-6df5d67e91d0)
![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/f17b6bcd-1323-4062-adb8-a10420ebe86e)

- Utilizando el comando “terraform fmt”, para aplicar un formato a nuestro código.
![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/d7c7b483-c5cf-48ef-87fb-180cb8f24a26)

- Y por último, para crear nuestra infraestructura, “terraform apply”
![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/71638f5d-c21b-4cd2-a02e-5577fe341510)
![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/8deeefb7-b63c-49d6-a17d-12c57ccbe63b)

-Evidencia del funcionamiento.
![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/b528002b-954b-4ab3-a6fb-df333cefdc26)


AZURE.

![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/9d472f6e-28ed-4575-9bb4-f1eb4b4b3f88)
![image](https://github.com/Sebastianavia/azfunction-tf/assets/71205906/f9d535fe-528a-4043-aeaa-201c678860c2)

