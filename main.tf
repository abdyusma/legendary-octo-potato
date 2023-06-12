provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "example" {
  name     = "pandai"
}

resource "azurerm_virtual_network" "example" {
  name                = "pandai-vnet"
  location            = "eastus"
  resource_group_name = data.azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "example" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/24"]
  # service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "dlg-Microsoft.DBforMySQL-flexibleServers"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "example" {
  name                = "pandai.private.mysql.database.azure.com"
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "d5vb7pibvforq"
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
  resource_group_name   = data.azurerm_resource_group.example.name
}

resource "azurerm_mysql_flexible_server" "example" {
  name                   = "pandai"
  resource_group_name    = data.azurerm_resource_group.example.name
  location               = "eastus"
  administrator_login    = "dbadmin"
  administrator_password = "H@Sh1CoR3!"
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.example.id
  private_dns_zone_id    = azurerm_private_dns_zone.example.id
  sku_name               = "GP_Standard_D2ads_v5"
  zone                   = "2"

  high_availability {
    mode = "ZoneRedundant"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.example]

  lifecycle {
    ignore_changes = [
      administrator_password
    ]
  }
}
