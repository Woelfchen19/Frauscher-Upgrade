dotnet
{
    assembly("System.Data")
    {
        Version = '4.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = 'b77a5c561934e089';

        type("System.Data.SqlClient.SqlConnection"; "UPG SqlConnectionNVX")
        {
        }
        type("System.Data.ConnectionState"; "UPG ConnectionStateNVX")
        {
        }

        type("System.Data.SqlClient.SqlCommand"; "UPG SqlCommandNVX")
        {
        }

        type("System.Data.SqlClient.SqlDataReader"; "UPG SqlDataReaderNVX")
        {
        }

        type("System.Data.SqlClient.SqlInfoMessageEventArgs"; "UPG SqlInfoMessageEventArgsNVX")
        {
        }

        type("System.Data.StateChangeEventArgs"; "UPG StateChangeEventArgsNVX")
        {
        }
    }

    assembly("System.Xml")
    {
        Version = '4.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = 'b77a5c561934e089';

        type("System.Xml.XmlDocument"; "UPG XmlDocumentNVX")
        {
        }

        type("System.Xml.XmlNode"; "UPG XmlNodeNVX")
        {
        }

        type("System.Xml.XmlAttribute"; "UPG XmlAttributeNVX")
        {
        }
    }

    assembly("mscorlib")
    {
        Version = '4.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = 'b77a5c561934e089';

        type("Microsoft.Win32.Registry"; "UPG RegistryNVX")
        {
        }
    }
}