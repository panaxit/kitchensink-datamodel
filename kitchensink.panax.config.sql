-- /////////////////////////////////////////////////// --
-- /////////////////////////////////////////////////// --
-- 
--					Kitchensink Demo
--
--				  Panax Configurations
--
-- /////////////////////////////////////////////////// --
-- /////////////////////////////////////////////////// --

-- INSTALLING

-- #panax.install 'C:\Users\benoror\Dropbox\panax\clones\panaxdb\dist\Panax.xml'
-- #panax.downgrade 'C:\Users\benoror\Dropbox\panax\clones\panaxdb\dist\Panax.xml'

SELECT @@version as vendor_ver, #database.getConfig('px:version') AS panaxdb_ver, #database.getProperty('px:App_Path') AS panaxdb_path

-- SELECT #database.getProperty('px:App_Path')
-- EXEC #database.setProperty 'px:App_Path', 'C:\Users\Administrador\Documents\panax-datamodel-kitchensink'

-- CLEANING

EXEC [$Ver:Beta_12].clearCache

EXEC [$Metadata].rebuild

-- REBUILD TRIGGER

-- DISABLE TRIGGER AutoRebuild ON DATABASE
-- ENABLE TRIGGER AutoRebuild ON DATABASE

-----------------------


-- MISC

SELECT * FROM [$Ver:Beta_12].InformationSchema 

EXEC [$Ver:Beta_12].RebuildXSD

EXEC [$Security].Authenticate 'webmaster', 'tests'

EXEC [$Security].UserSitemap @@userId=-1

-- CLI
-- CONFIG LIST
EXEC [$Table].exportConfig
EXEC [$Table].config 
EXEC [$Table].config 'dbo.Logs'
EXEC [$Table].config 'dbo.Logs', 'Nombre'
EXEC [$Table].clearConfig 'dbo.Logs', 'Nombre', '@whatever'
EXEC [$Table].config 'dbo.Logs', 'Nombre', '@whatever', 'a'
-- CONFIG REMOVE
EXEC [$Table].clearConfig  
EXEC [$Table].clearConfig 'dbo.Logs'
EXEC [$Table].clearConfig 'dbo.Logs', 'Nombre', '@whatever'
-- CACHE CLEAR
EXEC [$Ver:Beta_12].clearCache
EXEC [$Ver:Beta_12].clearCache 'dbo.Empleado2'
-- METADATA
EXEC [$Metadata].rebuild

-- /////////////////////////////////////////////////// --
--
--				   dbo.CONTROLS_Basic
--
-- /////////////////////////////////////////////////// --

--formView/insert
EXEC [$Ver:Beta_12].getXmlData @@userId=-1, @tableName='dbo.CONTROLS_Basic', @output=json, @getData=1, @getStructure=1, @rebuild=DEFAULT, @controlType=formView, @mode='insert', @pageIndex=DEFAULT, @pageSize=DEFAULT, @maxRecords=DEFAULT, @parameters=DEFAULT, @filters=DEFAULT, @sorters=DEFAULT, @fullPath=DEFAULT, @columnList=DEFAULT, @lang=DEFAULT

--formView/edit
EXEC [$Ver:Beta_12].getXmlData @@UserId=-1, @TableName='dbo.CONTROLS_Basic', @Mode='edit', @ControlType=formView, @PageIndex=DEFAULT, @PageSize=DEFAULT, @MaxRecords=DEFAULT, @Parameters=DEFAULT, @lang=DEFAULT, @Filters='[Id]=218', @output='json', @getStructure=1, @getData=1

--formView/filters
EXEC [$Ver:Beta_12].getXmlData @@userId=-1, @tableName='[dbo].[CONTROLS_Basic]', @output=json, @getData=1, @getStructure=1, @rebuild=DEFAULT, @controlType=formView, @mode='filters', @pageIndex=1, @pageSize=1, @maxRecords=DEFAULT, @parameters=DEFAULT, @filters=DEFAULT, @sorters=DEFAULT, @fullPath=DEFAULT, @columnList=DEFAULT, @lang=DEFAULT

EXEC [$Table].config 'dbo.CONTROLS_Basic[@controlType="formView" and @mode="filters"]', 'ShortTextField', '@mode', 'inherit';
EXEC [$Ver:Beta_12].clearCache 'dbo.CONTROLS_Basic'
EXEC [$Metadata].rebuild

EXEC [$Tools].getFilterString  

--gridView/edit
EXEC [$Ver:Beta_12].getXmlData @@userId=-1, @tableName='dbo.CONTROLS_Basic', @output=json, @getData=1, @getStructure=1, @controlType=gridView, @mode='edit', @pageSize=100




SELECT * FROM [$Metadata].Columns C WHERE C.Table_Name='CONTROLS_Basic'
SELECT * FROM [$Metadata].Tables C WHERE C.Table_Name='CONTROLS_Basic'

EXEC [$Table].config 'dbo.CONTROLS_Basic', 'Combobox', '@controlType', 'combobox';
EXEC [$Table].config 'dbo.CONTROLS_Basic', 'Money', '@tab', 'Otros';
EXEC [$Table].config 'dbo.CONTROLS_Basic', 'RadioGroup', '@controlType', 'radiogroup';
EXEC [$Table].config 'dbo.CONTROLS_Basic', 'RadioGroup', '@moveBefore', 'Combobox';
EXEC [$Table].config 'dbo.CONTROLS_Basic', 'ShortTextField', '@tab', 'General';
EXEC [$Table].config 'dbo.CONTROLS_Basic', 'ShortTextField', '@tabPanel', 'General';
EXEC [$Table].config 'dbo.CONTROLS_Basic[@controlType="gridView"]', 'ShortTextField', '@mode', 'inherit';
EXEC [$Table].config 'dbo.CONTROLS_Basic[@controlType="gridView"]', 'Integer', '@mode', 'inherit';


EXEC [$Ver:Beta_12].clearCache 'dbo.CONTROLS_Basic'

EXEC [$Metadata].rebuild


-- /////////////////////////////////////////////////// --
--
--				dbo.CONTROLS_Advanced
--			  + dbo.CONTROLS_Profiles  - Junction Table
--				  + dbo.Profiles       - Self-ref Table
--
-- /////////////////////////////////////////////////// --


EXEC [$Ver:Beta_12].getXmlData @@UserId=-1, @TableName='dbo.CONTROLS_Advanced', @Mode=edit, @ControlType=formView, @PageIndex=DEFAULT, @PageSize=DEFAULT, @MaxRecords=DEFAULT, @Parameters=DEFAULT, @lang=DEFAULT, @output='json', @getStructure=1, @getData=1

EXEC [$Table].config 'dbo.CONTROLS_Advanced', 'Color', '@moveBefore', 'FileUpload'

--------------------------
-- -- JUNCTION TABLE -- --
--------------------------

EXEC [$Table].config 'dbo.CONTROLS_Advanced', 'CONTROLS_Profiles', '@headerText', 'Profiles (Junction Table)'
-- Scaffold junction table
EXEC [$Table].config 'dbo.CONTROLS_Advanced', 'CONTROLS_Profiles', 'scaffold', 'true';
-- Scaffold true for tree structure, false for flat structure
EXEC [$Table].config 'dbo.CONTROLS_Advanced', 'CONTROLS_Profiles', '//ForeignKey[@Column_Name="IdParent"]/@scaffold', 'true';
-- @minSelections & @maxSelections are ignored and set to '1' when unique key
EXEC [$Table].config 'dbo.CONTROLS_Advanced', 'CONTROLS_Profiles', '@minSelections', '3'
EXEC [$Table].config 'dbo.CONTROLS_Advanced', 'CONTROLS_Profiles', '@maxSelections', '5'
-- Create Unique Key (forcing @maxSelections=1)
/*
ALTER TABLE dbo.CONTROLS_Profiles ADD CONSTRAINT
            UK_CONTROLS_Profiles UNIQUE NONCLUSTERED
    (
                IdControl
    )
*/
-- Remove Unique Key
/*
ALTER TABLE dbo.CONTROLS_Profiles
DROP CONSTRAINT UK_CONTROLS_Profiles;
*/


--------------------------
-- -- SELF-REF TABLE -- --
--------------------------

EXEC [$Table].config 'dbo.CONTROLS_Advanced', 'IdProfile', '@headerText', 'Profiles (Self-ref Table)'
-- Scaffold self-ref table
EXEC [$Table].config 'dbo.CONTROLS_Advanced', 'IdProfile', 'scaffold', 'true';
-- Scaffold true for tree structure, false for flat structure
EXEC [$Table].config 'dbo.CONTROLS_Advanced', 'IdProfile', '//ForeignKey[@Column_Name="IdParent"]/@scaffold', 'true';

EXEC [$Ver:Beta_12].clearCache 'dbo.CONTROLS_Advanced'
EXEC [$Ver:Beta_12].clearCache 'dbo.CONTROLS_Profiles'
EXEC [$Ver:Beta_12].clearCache 'dbo.Profiles'
EXEC [$Metadata].rebuild

SELECT * FROM [$Ver:Beta_12].InformationSchema


-- /////////////////////////////////////////////////// --
--
--				dbo.CONTROLS_Cascaded
--				  CatalogosSistema.Pais
--				    CatalogosSistema.Estado
--				      CatalogosSistema.Municipio
--
-- /////////////////////////////////////////////////// --

EXEC [$Table].config 'CatalogosSistema.Pais', '', 'displayText', 'Pais';
EXEC [$Table].config 'CatalogosSistema.Estado', '', 'displayText', 'Estado';
EXEC [$Table].config 'CatalogosSistema.Municipio', '', 'displayText', 'Municipio';
EXEC [$Ver:Beta_12].clearCache 'CatalogosSistema.Pais'
EXEC [$Ver:Beta_12].clearCache 'CatalogosSistema.Estado'
EXEC [$Ver:Beta_12].clearCache 'CatalogosSistema.Municipio'
EXEC [$Ver:Beta_12].clearCache 'dbo.CONTROLS_Cascaded'
EXEC [$Metadata].rebuild

-- formView / edit

EXEC [$Ver:Beta_12].getXmlData @@UserId=-1, @tableName='dbo.CONTROLS_Cascaded', @output=json, @getData=1, @getStructure=1, @rebuild=DEFAULT, @controlType=formView, @mode='edit', @pageIndex=DEFAULT, @pageSize=DEFAULT, @maxRecords=DEFAULT, @parameters=DEFAULT, @filters='id=1', @sorters=DEFAULT, @fullPath=DEFAULT, @columnList=DEFAULT, @lang=DEFAULT


EXEC [$Ver:Beta_12].clearCache 'dbo.CONTROLS_Cascaded'
EXEC [$Metadata].rebuild


--formView/insert
EXEC [$Ver:Beta_12].getXmlData @@userId=-1, @tableName='dbo.Empleado', @output=json, @getData=1, @getStructure=1, @rebuild=DEFAULT, @controlType=formView, @mode='insert', @pageIndex=DEFAULT, @pageSize=DEFAULT, @maxRecords=DEFAULT, @parameters=DEFAULT, @filters=DEFAULT, @sorters=DEFAULT, @fullPath=DEFAULT, @columnList=DEFAULT, @lang=DEFAULT

-- /////////////////////////////////////////////////// --
--
--			CentrosDeCostos.CentroDeCostos
--
-- /////////////////////////////////////////////////// --

-- cardsView / readonly

EXEC [$Ver:Beta_12].getXmlData @@userId=-1, @tableName='[CentrosDeCostos].[CentroDeCostos]', @output=json, @getData=1, @getStructure=1, @rebuild=DEFAULT, @controlType=cardsView, @mode='readonly', @pageIndex=DEFAULT, @pageSize=DEFAULT, @maxRecords=DEFAULT, @parameters=DEFAULT, @filters=DEFAULT, @sorters=DEFAULT, @fullPath=DEFAULT, @columnList=DEFAULT, @lang=DEFAULT

select * from [$Ver:Beta_12].InformationSchema

EXEC [$Ver:Beta_12].clearCache '[CentrosDeCostos].[CentroDeCostos]'

EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', '', '@custom:titleField', 'Nombre';
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', '', '@custom:iconField', 'Imagen';
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', '', '@custom:descField1', 'Tipo';
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', '', '@custom:descField2', 'DireccionFisica';
	
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', 'Imagen', '${table}[@controlType=''cardsView'']/${column}/@mode', 'inherit';
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', 'Imagen', '@mode', 'inherit';
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', 'Nombre', '${table}[@controlType=''cardsView'']/${column}/@mode', 'inherit';
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', 'Nombre', '@mode', 'inherit';
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', 'NombreReal', '${table}[@controlType=''cardsView'']/${column}/@mode', 'inherit';
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', 'NombreReal', '@mode', 'inherit';
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', 'Tipo', '${table}[@controlType=''cardsView'']/${column}/@mode', 'inherit';
EXEC [$Table].config 'CentrosDeCostos.CentroDeCostos', 'Tipo', '@mode', 'inherit';


-- /////////////////////////////////////////////////// --
--
--				dbo.CONTROLS_NestedForm
--				  dbo.CONTROLS_NestedGrid
--					dbo.CONTROLS_Grid
--
-- /////////////////////////////////////////////////// --

-- formView / edit

EXEC [$Ver:Beta_12].getXmlData @@userId=-1, @tableName='dbo.CONTROLS_NestedForm', @output=json, @getData=1, @getStructure=1, @rebuild=DEFAULT, @controlType=formView, @mode='edit', @pageIndex=DEFAULT, @pageSize=DEFAULT, @maxRecords=DEFAULT, @parameters=DEFAULT, @filters='id=1', @sorters=DEFAULT, @fullPath=DEFAULT, @columnList=DEFAULT, @lang=DEFAULT

EXEC [$Table].config 'dbo.CONTROLS_NestedForm[@controlType="gridView"]', 'TextLimit10Chars', '@mode', 'inherit';



EXEC [$Table].config 'dbo.CONTROLS_NestedForm[@controlType="formView"]', 'CONTROLS_NestedGrid', '@controlType', 'formView';

EXEC [$Ver:Beta_12].clearCache 'dbo.CONTROLS_NestedForm'
EXEC [$Metadata].rebuild


-- /////////////////////////////////////////////////// --
--
--				dbo.CONTROLS_NestedGrid
--				  dbo.CONTROLS_Grid
--
-- /////////////////////////////////////////////////// --

-- formView / edit

[$Ver:Beta_12].getXmlData @@userId=-1, @tableName='dbo.CONTROLS_NestedGrid', @output=json, @getData=1, @getStructure=1, @rebuild=DEFAULT, @controlType=formView, @mode='edit', @pageIndex=DEFAULT, @pageSize=DEFAULT, @maxRecords=DEFAULT, @parameters=DEFAULT, @filters='id=1', @sorters=DEFAULT, @fullPath=DEFAULT, @columnList=DEFAULT, @lang=DEFAULT


EXEC [$Table].config 'dbo.CONTROLS_NestedGrid[@controlType="formView"]', 'CONTROLS_Grid', '@controlType', 'cardsView';
EXEC [$Table].config 'CONTROLS_Grid', '', '@custom:titleField', 'Name';
EXEC [$Table].config 'CONTROLS_Grid', '', '@custom:iconField', 'Image';
EXEC [$Table].config 'CONTROLS_Grid', '', '@custom:descField1', 'Field1';
EXEC [$Table].config 'CONTROLS_Grid', '', '@custom:descField2', 'Field2';
EXEC [$Table].config 'dbo.CONTROLS_NestedGrid', 'CONTROLS_Grid', '@mode', 'inherit';
EXEC [$Table].config 'dbo.CONTROLS_NestedGrid', 'CONTROLS_Grid', 'scaffold', 'true';
EXEC [$Table].config 'dbo.CONTROLS_Grid', 'Name255', '@mode', 'inherit';
EXEC [$Table].config 'dbo.CONTROLS_Grid', 'Image', '@mode', 'inherit';
EXEC [$Table].config 'dbo.CONTROLS_Grid', 'Field1', '@mode', 'inherit';
EXEC [$Table].config 'dbo.CONTROLS_Grid', 'Field2', '@mode', 'inherit';
EXEC [$Ver:Beta_12].clearCache 'dbo.CONTROLS_NestedGrid'
EXEC [$Ver:Beta_12].clearCache 'dbo.CONTROLS_Grid'
EXEC [$Metadata].rebuild


-- /////////////////////////////////////////////////// --
--
--				    dbo.Empleado2
--
-- /////////////////////////////////////////////////// --

EXEC [$Ver:Beta_12].getXmlData @@UserId=-1, @TableName='dbo.Empleado2', @Mode=DEFAULT, @ControlType=form, @PageIndex=DEFAULT, @PageSize=DEFAULT, @MaxRecords=DEFAULT, @Parameters=DEFAULT, @lang=DEFAULT, @output='json', @getStructure=1, @getData=1

--FileTemplate

EXEC [$Table].config  'dbo.Empleado2', '', '@fileTemplate', 'ResumenEmpleado.html'
EXEC [$Table].config  'dbo.Empleado2', '', '@fileTemplate', 'CredencialEmpleado.svg'


EXEC [$Ver:Beta_12].clearCache 'dbo.Empleado2'

EXEC [$Ver:Beta_12].getXmlData @@UserId=-1, @FullPath='', @TableName='dbo.Empleado2', @Mode=DEFAULT, @ControlType=fileTemplate, @PageIndex=DEFAULT, @PageSize=DEFAULT, @MaxRecords=DEFAULT, @Filters='id=1', @Parameters=DEFAULT, @lang=DEFAULT, @output='html', @getStructure=1, @getData=1