## **Infraestructura como código - practica 1 Terraform**

---

### Pablo Fernando Pineda Patiño - A00395831

#### Autenticación en azure:
Digitamos ``az login``, ingresamos con nuestra cuenta asociada y posteriormente la suscripción que tenemos.

<img width="1473" height="564" alt="image" src="https://github.com/user-attachments/assets/4620ac22-089d-497b-a5c6-39b529cd8d57" />

Luego se ejecutó el comando ``az account show`` para ver la información de la suscripción activa en la sesión actual para obtener datos que nos serán útiles más adelante.

<img width="531" height="342" alt="image" src="https://github.com/user-attachments/assets/9102926a-5efa-4a29-8f12-27015c32c37f" />

#### inicializar terraform
Ahora, se hace uso del comando ``terraform init`` que descarga proveedores, módulos y configura el backend para que poder empezar a planear y aplicar infraestructura.

<img width="1198" height="810" alt="image" src="https://github.com/user-attachments/assets/d60dbe2b-fe6e-4ec6-8d32-f5c791d67df3" />


#### Añadir subscripción de azure en el provider
con la información que habiamos obtenido previamente añadimos la ``subscription_id`` en el provider para asegurar que los recursos se creen exactamente en la suscripción correcta.

<img width="1034" height="638" alt="image" src="https://github.com/user-attachments/assets/4e43cbb4-b30c-481d-815f-8211578ef52a" />

#### Comprobar la correcta sintaxis del los archivos .tf
Haciendo uso del comando ``terraform validate`` se comprueba que el código tenga una sintaxis y configuración correcta.
Si no tiene una sintaxis correcta se usa el comando ``terraform fmt`` para arregla el estilo y formato.

#### Generar y revisar el plan de ejecución
Haciendo uso del comando: ``terraform plan``
Terraform compara la configuración definida en los archivos .tf con el estado real de la infraestructura existente en Azure (u otro proveedor). De esta forma, genera un plan de ejecución que muestra los cambios que se llevarían a cabo en caso de aplicar la configuración:

``+`` Recursos que se crearían.

``~`` Recursos que se modificarían.

``-`` Recursos que se eliminarían.

Este paso permite previsualizar los cambios y asegurarse de que la infraestructura resultante coincida con lo esperado, antes de ejecutar modificaciones reales.

<img width="1131" height="537" alt="image" src="https://github.com/user-attachments/assets/efa16579-a43a-4e23-befb-a051af29ec61" />

#### Aplicar el plan de ejecución
Haciendo uso del comando: ``terraform apply``

Terraform toma el plan de ejecución previamente generado y lo aplica realmente sobre la infraestructura. Esto significa que se crean, modifican o eliminan los recursos en Azure (u otro proveedor) según lo definido en los archivos .tf.

Durante este proceso:

- Terraform vuelve a generar el plan y lo muestra en pantalla.

- Solicita confirmación del usuario (yes) antes de ejecutar los cambios.

- Una vez completado, actualiza el archivo de estado (terraform.tfstate) para reflejar la infraestructura actual.

De esta forma, terraform apply es el paso en el que los cambios dejan de ser una simulación y se convierten en recursos reales.

<img width="821" height="383" alt="image" src="https://github.com/user-attachments/assets/5dfee6e8-c041-47b6-acc0-6e8b6c1d1739" />

### verificar todo haya funcionado
vamos a portal azure y en el apartado de grupo de recursos, seleccionamos el que creamos y se puede observar que se desplegaron tres recursos:
- almacenamiento
- plan de App Service
- aplicación de funciones

<img width="1727" height="706" alt="image" src="https://github.com/user-attachments/assets/ea373f7f-ebef-4c10-b7f0-6828d427742a" />

Accedemos a la url para verificar que funciona:

<img width="651" height="249" alt="image" src="https://github.com/user-attachments/assets/cc80161c-4d24-4a4c-81f3-3f0f2f6c95c7" />

