Reporte de Terraform

Estudiante: Juan Felipe Jojoa Crespo
Codigo: A00382042

Pasos llevados a cabo para lograr subir la funcion en Azure:

1. Instalacion de Terraform
   - Descargar e instalar Terraform desde el sitio oficial: https://www.terraform.io/downloads.html
   - Verificar la instalacion ejecutando `terraform -v` en la terminal.

2. Configuracion de Azure CLI
   - Descargar e instalar Azure CLI desde: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
   - Iniciar sesion en Azure ejecutando `az login` y seguir las instrucciones para autenticar.
    - Seleccionar la suscripcion adecuada con `az account set --subscription "NombreDeLaSuscripcion"`.
    - Verificar la configuracion ejecutando `az account show`.
    - Crear un grupo de recursos en Azure con `az group create --name NombreDelGrupo --location eastus`.
    - Crear un servicio principal para la autenticacion con `az ad sp create-for-rbac --name "NombreDelServicio" --role Contributor --scopes /subscriptions/{subscription-id}/resourceGroups/NombreDelGrupo`.
    - Guardar las credenciales del servicio principal (appId, password, tenant) para usarlas en Terraform.

3. Configuracion de Terraform
   - Crear un archivo `main.tf` con la configuracion de Terraform.

    provider "azurerm" {
    features {}
    subscription_id = "16373f90-08c6-4486-ac06-70fe43529e9b"
  }

  Ponemos el ID de la cuenta correspondiente, en este caso la mia para que este vinculada a mi Azure.

  Revisar el archivo variables.tf, ya que detecte un problema con la region de europa que veina por defecto me toco buscar que regiones admitia mi suscrpicion de Azure, en mi caso me acepto la eastus2 y la modifique tal como se ve aqui:

  variable "location" {
  type        = string
  default     = "eastus2"
  description = "Location"
}

4. Ya una con la configuracion lista, ejecutar los siguientes comandos en la terminal:
   - `terraform init` para inicializar el proyecto.
   - `terraform plan` para ver el plan de ejecucion y verificar que todo este correcto.
   - `terraform apply` para aplicar la configuracion y crear los recursos en Azure. Confirmar la aplicacion cuando se solicite.

  5. Verificar en el portal de Azure que los recursos se hayan creado correctamente y que la funcion este desplegada.

  En mi caso esta fue la url que me devolvio el output del codigo, es decir la salida del terraform apply: url = "https://jojoafuncsa123.azurewebsites.net/api/jojoafuncsa123"

  Pero si vamos desde Azure el link es este: "https://jojoafuncsa123.azurewebsites.net" , esta pagina lleva a una interfaz web visual que me muestra que mi funcion esta desplegada y funcionando correctamente.

  Pantallazos adjuntos de la practica realizada:

  Figura 1: Imagen Correspondiente a la ejecucion del comando terraform init
  ![Terraform Init](images/terrainit.png)
  
  Figura 2: Imagen Correspondiente a la ejecucion del comando terraform plan
  ![Terraform Plan](images/terraplan.png)

  Figura 3: Imagen Correspondiente a la ejecucion del comando terraform apply
  ![Terraform Apply](images/terraapply.png)

  Figura 4: Imagen Correspondiente a la funcion desplegada en Azure
  ![Azure Function](images/azure.png)
