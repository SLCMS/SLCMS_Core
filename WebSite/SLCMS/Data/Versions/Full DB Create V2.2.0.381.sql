IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'SLCMS_dev')
	DROP DATABASE [SLCMS_dev]
GO

CREATE DATABASE [SLCMS_dev]  ON (NAME = N'SLCMS_dev_Data', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLEXPRESS\MSSQL\DATA\SLCMS_dev_Data.MDF' , SIZE = 3, FILEGROWTH = 10%) LOG ON (NAME = N'SLCMS_dev_Log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLEXPRESS\MSSQL\DATA\SLCMS_dev_Log.LDF' , SIZE = 41, FILEGROWTH = 10%)
 COLLATE SQL_Latin1_General_CP1_CI_AS
GO

exec sp_dboption N'SLCMS_dev', N'autoclose', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'bulkcopy', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'trunc. log', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'torn page detection', N'true'
GO

exec sp_dboption N'SLCMS_dev', N'read only', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'dbo use', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'single', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'autoshrink', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'ANSI null default', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'recursive triggers', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'ANSI nulls', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'concat null yields null', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'cursor close on commit', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'default to local cursor', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'quoted identifier', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'ANSI warnings', N'false'
GO

exec sp_dboption N'SLCMS_dev', N'auto create statistics', N'true'
GO

exec sp_dboption N'SLCMS_dev', N'auto update statistics', N'true'
GO

if( (@@microsoftversion / power(2, 24) = 8) and (@@microsoftversion & 0xffff >= 724) )
	exec sp_dboption N'SLCMS_dev', N'db chaining', N'false'
GO

use [SLCMS_dev]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Nexts]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Nexts]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RRDB_MasterControl]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[RRDB_MasterControl]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_AuditTrail_SystemLoginOuts]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_AuditTrail_SystemLoginOuts]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Admin_UserDetails]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Admin_UserDetails]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Admin_UserRoles]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Admin_UserRoles]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Blog_Blogs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Blog_Blogs]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Blog_Categories]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Blog_Categories]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Content_Content]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Content_Content]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Content_Control_Blog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Content_Control_Blog]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Content_Control_Document]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Content_Control_Document]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Content_Control_Object]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Content_Control_Object]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_FormData_Default_ContactUs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_FormData_Default_ContactUs]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_FormData_Default_SLCMSlogin]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_FormData_Default_SLCMSlogin]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_FormData_Pasta_Deli_Wholesale]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_FormData_Pasta_Deli_Wholesale]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_FormData_Pasta_Retail]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_FormData_Pasta_Retail]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_FormData_Pasta_Wholesale]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_FormData_Pasta_Wholesale]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_FormData_SACF_SACFContactUs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_FormData_SACF_SACFContactUs]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Object_Data_Data]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Object_Data_Data]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Object_Data_Definition]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Object_Data_Definition]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Object_Data_Images]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Object_Data_Images]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Object_Description]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Object_Description]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Object_PhotoGalleries]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Object_PhotoGalleries]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Object_Shops]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Object_Shops]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_PageStructure]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_PageStructure]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_Roles]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_Roles]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Site_0_wiki_LabelMapping]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Site_0_wiki_LabelMapping]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_System_Admin_UserDetails]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_System_Admin_UserDetails]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_System_Admin_UserRoles]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_System_Admin_UserRoles]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_System_PortalControl]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_System_PortalControl]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_System_PortalParentDocs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_System_PortalParentDocs]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_System_PortalURLs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_System_PortalURLs]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_System_VersionControl]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_System_VersionControl]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Type_Content]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Type_Content]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Type_Document]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Type_Document]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Type_Template]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Type_Template]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SLCMS_Type_User_StaffRoles]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SLCMS_Type_User_StaffRoles]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Stats_PacketStore]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Stats_PacketStore]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[theThread_Links]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[theThread_Links]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[theThread_Matrix]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[theThread_Matrix]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[theThread_Sets]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[theThread_Sets]
GO

CREATE TABLE [dbo].[Nexts] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[flag_CurrentData] [bit] NOT NULL ,
	[NextTimeStamp] [datetime] NULL ,
	[IDName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NextIDValue] [int] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[RRDB_MasterControl] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[CounterNameList] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CounterCount] [int] NULL ,
	[RefreshRate] [int] NULL ,
	[StoreFullName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AddMethod] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DataStoreMode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[StoreStatus] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[StoreOKtoUse] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_AuditTrail_SystemLoginOuts] (
	[LogID] [int] NULL ,
	[AuditLogTime] [datetime] NULL ,
	[User_Login] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User_Password] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Activity] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User_System_Role] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RepID]  uniqueidentifier ROWGUIDCOL  NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Admin_UserDetails] (
	[UserID] [int] NULL ,
	[User_Login] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User_Password] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User_FullName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Global_RoleBits] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Global_RoleValue] [int] NOT NULL ,
	[User_Active] [bit] NOT NULL ,
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Admin_UserRoles] (
	[UserID] [int] NULL ,
	[SiteID] [int] NOT NULL ,
	[ModuleID] [int] NULL ,
	[RoleBits] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RoleValue] [int] NOT NULL ,
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Blog_Blogs] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[BlogID] [int] NULL ,
	[BlogTitle] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BlogNavName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BlogURLname] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BlogDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DO] [int] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Blog_Categories] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[BlogID] [int] NULL ,
	[BlogCategoryID] [int] NOT NULL ,
	[BlogCategoryTitle] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BlogCategoryNavName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BlogCategoryURLName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BlogCategoryDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Version] [int] NOT NULL ,
	[VersionTimeStamp] [datetime] NULL ,
	[DO] [int] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Content_Content] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[ContentID] [int] NULL ,
	[ContentChunk] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ContentChunkNumber] [int] NULL ,
	[flag_CurrentVersion] [bit] NOT NULL ,
	[ContentTypeID] [int] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Content_Control_Blog] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[Version] [int] NOT NULL ,
	[VersionTimeStamp] [datetime] NULL ,
	[BlogID] [int] NOT NULL ,
	[BlogCategoryID] [int] NOT NULL ,
	[BlogEntryID] [int] NOT NULL ,
	[EntryDate] [datetime] NULL ,
	[ContentID] [int] NOT NULL ,
	[Summary] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BlogURL] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Content_Control_Document] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[Version] [int] NOT NULL ,
	[VersionTimeStamp] [datetime] NULL ,
	[ContentHandle] [char] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ContentTypeID] [int] NOT NULL ,
	[DocID] [int] NOT NULL ,
	[ContainerID] [int] NOT NULL ,
	[ContainerName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ContentID] [int] NOT NULL ,
	[EditorMode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[flag_LiveVersion] [bit] NOT NULL ,
	[UserID_EditedBy] [int] NOT NULL ,
	[UserID_PublishedBy] [int] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Content_Control_Object] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[ItemID] [int] NULL ,
	[Name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ImageID] [int] NULL ,
	[ProductID] [int] NULL ,
	[VersionTimeStamp] [datetime] NULL ,
	[Version] [int] NOT NULL ,
	[ItemHandle] [char] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ContentID] [int] NULL ,
	[flag_LiveVersion] [bit] NOT NULL ,
	[UserID_EditedBy] [int] NULL ,
	[UserID_PublishedBy] [int] NULL ,
	[ShortDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Object_Data_Data] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NULL ,
	[ObjectID] [int] NULL ,
	[FieldNumber] [int] NULL ,
	[FieldData] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Object_Data_Definition] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[ObjectID] [int] NULL ,
	[FieldNumber] [int] NULL ,
	[FieldName] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Object_Data_Images] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[ImageID] [int] NULL ,
	[Filename_RawFile] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_date_taken] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_Manufacturer] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_Exposure] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_focallength] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_flash] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_aperture] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_Model] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_ExposureProgram] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_FNumber] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_PixelXDimension] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EXIF_PixelYDimension] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Object_Description] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[ObjectID] [int] NULL ,
	[ObjectName] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ShortDescription] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LongDescription] [ntext] COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Defining] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DO] [int] NOT NULL ,
	[Time2Start] [datetime] NULL ,
	[Time2Stop] [datetime] NULL ,
	[flgActive] [int] NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Object_PhotoGalleries] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[PhotogalleryGalleryID] [int] NULL ,
	[PhotoGalleryName] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Object_Shops] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[ShopID] [int] NULL ,
	[ShopName] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_PageStructure] (
	[DocID] [int] NOT NULL ,
	[ParentID] [int] NULL ,
	[DefaultDocID] [int] NULL ,
	[DocType] [int] NULL ,
	[Param1] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Param2] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Param3] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Param4] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DO] [int] NULL ,
	[HasContent] [bit] NULL ,
	[IsParent] [bit] NULL ,
	[Children] [int] NULL ,
	[Hidden] [int] NULL ,
	[Navname] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[URLName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[URLNameEncoded] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[IsHomePage] [bit] NULL ,
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_Roles] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[RoleID] [int] NULL ,
	[Role_Description] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Role_DefaultPermissions] [int] NULL ,
	[Role_HomeDocID] [int] NOT NULL ,
	[DO] [int] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Site_0_wiki_LabelMapping] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[DocID] [int] NOT NULL ,
	[WikiID] [int] NOT NULL ,
	[Label] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DateCreated] [datetime] NULL ,
	[flag_CurrentLabel] [bit] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_System_Admin_UserDetails] (
	[UserID] [int] NULL ,
	[User_Login] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User_Password] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User_FullName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Global_RoleValue] [int] NOT NULL ,
	[Global_RoleBits] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[User_Active] [bit] NOT NULL ,
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_System_Admin_UserRoles] (
	[UserID] [int] NULL ,
	[SiteID] [int] NULL ,
	[ModuleID] [int] NULL ,
	[RoleBits] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RoleValue] [int] NOT NULL ,
	[RepID]  uniqueidentifier ROWGUIDCOL  NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_System_PortalControl] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[SubSiteID] [int] NULL ,
	[SubSiteFriendlyName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RootDocID] [int] NULL ,
	[flagAllowSubSite] [int] NULL ,
	[SubSiteShortName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SubSiteActive] [bit] NOT NULL ,
	[DO] [int] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_System_PortalParentDocs] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[SubSiteID] [int] NULL ,
	[ParentDocID] [int] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_System_PortalURLs] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NULL ,
	[SubSiteURLID] [int] NULL ,
	[SubSiteID] [int] NULL ,
	[SubSiteURL] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DO] [int] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_System_VersionControl] (
	[flag_ActiveVersion] [int] NOT NULL ,
	[VersionNumber_Full] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[VersionNumber_Major] [int] NULL ,
	[VersionNumber_Minor] [int] NULL ,
	[VersionNumber_Dot] [int] NULL ,
	[VersionNumber_Revision] [int] NULL ,
	[VersionDate] [datetime] NULL ,
	[InstallDate] [datetime] NULL ,
	[ThroughDate] [datetime] NULL ,
	[RepID]  uniqueidentifier ROWGUIDCOL  NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Type_Content] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NULL ,
	[ContentTypeID] [int] NULL ,
	[ContentDescription] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DO] [int] NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Type_Document] (
	[DocType] [int] NULL ,
	[DocDesc] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DO] [int] NULL ,
	[Hidden] [int] NULL ,
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Type_Template] (
	[TemplateType] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TemplateDesc] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DO] [int] NULL ,
	[Hidden] [int] NULL ,
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SLCMS_Type_User_StaffRoles] (
	[User_RoleID] [int] NULL ,
	[User_RoleName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User_RoleDescription] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User_RoleBits] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DO] [int] NULL ,
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Stats_PacketStore] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[PacketName] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PacketStore] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[theThread_Links] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[ThreadSetID] [int] NULL ,
	[ThreadID] [int] NULL ,
	[ExternalValue] [int] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[theThread_Matrix] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[ThreadID_Left] [int] NOT NULL ,
	[ThreadID_Right] [int] NULL ,
	[ThreadSetID] [int] NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[theThread_Sets] (
	[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
	[ThreadSetID] [int] NULL ,
	[TableName] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FieldName] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Nexts] WITH NOCHECK ADD 
	CONSTRAINT [PK_Nexts] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[RRDB_MasterControl] WITH NOCHECK ADD 
	CONSTRAINT [PK_RRDB_MasterControl] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Blog_Blogs] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_Blog_Blogs] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Blog_Categories] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_Blog_Categories] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Content_Content] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_Document_Content_1] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Content_Control_Blog] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_Blog_Content] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Content_Control_Document] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_Document_Content] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Content_Control_Object] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_Content_Control_Object] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Object_Data_Definition] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLShop_Category0_Definitions] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Object_Description] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLShop_Category0_Description] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Object_PhotoGalleries] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_Object_PhotoGalleries] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Object_Shops] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_Object_Shops] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_System_PortalControl] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_System_PortalControl] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_System_PortalParentDocs] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_System_PortalParentDocs] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Type_Document] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_Type_Document] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SLCMS_Type_Template] WITH NOCHECK ADD 
	CONSTRAINT [PK_SLCMS_Type_Template] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Stats_PacketStore] WITH NOCHECK ADD 
	CONSTRAINT [PK_Stats_PacketStore] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[theThread_Links] WITH NOCHECK ADD 
	CONSTRAINT [PK_theThread_Links_1] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[theThread_Matrix] WITH NOCHECK ADD 
	CONSTRAINT [PK_theThread_Matrix] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[theThread_Sets] WITH NOCHECK ADD 
	CONSTRAINT [PK_theThread_Links] PRIMARY KEY  CLUSTERED 
	(
		[RepID]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Nexts] ADD 
	CONSTRAINT [DF_Nexts_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_Nexts_flag_CurrentData] DEFAULT (1) FOR [flag_CurrentData]
GO

ALTER TABLE [dbo].[RRDB_MasterControl] ADD 
	CONSTRAINT [DF_RRDB_MasterControl_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_AuditTrail_SystemLoginOuts] ADD 
	CONSTRAINT [DF_SLCMS_AuditTrail_SystemLoginOuts_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Admin_UserDetails] ADD 
	CONSTRAINT [DF_SLCMS_User_Users_User_RoleBits] DEFAULT ('00000000000000000000000000000000') FOR [Global_RoleBits],
	CONSTRAINT [DF_SLCMS_Site_0_Admin_Users_Global_RoleValue] DEFAULT (0) FOR [Global_RoleValue],
	CONSTRAINT [DF_SLCMS_Site_0_Admin_Users_User_Active] DEFAULT (0) FOR [User_Active],
	CONSTRAINT [DF_SLCMS_Users_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Admin_UserRoles] ADD 
	CONSTRAINT [DF_SLCMS_Site_0_Admin_UserRoles_SiteID] DEFAULT (0) FOR [SiteID],
	CONSTRAINT [DF_SLCMS_Site_0_Admin_UserRoles_RoleBits] DEFAULT ('00000000000000000000000000000000') FOR [RoleBits],
	CONSTRAINT [DF_SLCMS_Site_0_Admin_UserRoles_RoleValue] DEFAULT (0) FOR [RoleValue],
	CONSTRAINT [DF_SLCMS_Site_0_Admin_UserRoles_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Blog_Blogs] ADD 
	CONSTRAINT [DF_SLCMS_Blog_Blogs_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_Blog_Blogs_DO] DEFAULT (0) FOR [DO]
GO

 CREATE  INDEX [IX_SLCMS_Blog_Blogs_URLName] ON [dbo].[SLCMS_Site_0_Blog_Blogs]([BlogURLname]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_Blog_Blogs_NavName] ON [dbo].[SLCMS_Site_0_Blog_Blogs]([BlogNavName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Blog_Categories] ADD 
	CONSTRAINT [DF_SLCMS_Blog_Categories_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_Blog_Categories_BlogID] DEFAULT (0) FOR [BlogID],
	CONSTRAINT [DF_SLCMS_Blog_Categories_BlogCategoryID] DEFAULT (1) FOR [BlogCategoryID],
	CONSTRAINT [DF_SLCMS_Blog_Categories_Version] DEFAULT (0) FOR [Version],
	CONSTRAINT [DF_SLCMS_Blog_Categories_DO] DEFAULT (0) FOR [DO]
GO

 CREATE  INDEX [IX_SLCMS_Blog_Categories] ON [dbo].[SLCMS_Site_0_Blog_Categories]([BlogCategoryURLName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_Blog_Categories_URL] ON [dbo].[SLCMS_Site_0_Blog_Categories]([BlogCategoryURLName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_Blog_Categories_Nav] ON [dbo].[SLCMS_Site_0_Blog_Categories]([BlogCategoryNavName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Content_Content] ADD 
	CONSTRAINT [DF_SLCMS_Document_Content_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_Document_Content_flag_CurrentVersion_1] DEFAULT (1) FOR [flag_CurrentVersion],
	CONSTRAINT [DF_SLCMS_Content_Content_ContentTypeID] DEFAULT (1) FOR [ContentTypeID]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Content_Control_Blog] ADD 
	CONSTRAINT [DF_SLCMS_Blog_Content_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_Blog_Content_flag_CurrentVersion] DEFAULT (0) FOR [Version],
	CONSTRAINT [DF_SLCMS_Blog_Content_DocID] DEFAULT (0) FOR [BlogID],
	CONSTRAINT [DF_SLCMS_Blog_Content_ContainerID] DEFAULT (1) FOR [BlogCategoryID],
	CONSTRAINT [DF_SLCMS_Content_Control_Blog_EntryID] DEFAULT (0) FOR [BlogEntryID],
	CONSTRAINT [DF_SLCMS_Content_Control_Blog_ContentID] DEFAULT (0) FOR [ContentID]
GO

 CREATE  INDEX [IX_SLCMS_Blog_Content] ON [dbo].[SLCMS_Site_0_Content_Control_Blog]([EntryDate]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_Blog_Content_1] ON [dbo].[SLCMS_Site_0_Content_Control_Blog]([VersionTimeStamp]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_Content_Control_Blog_Date] ON [dbo].[SLCMS_Site_0_Content_Control_Blog]([EntryDate]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_Content_Control_Blog_VersionTimeStamp] ON [dbo].[SLCMS_Site_0_Content_Control_Blog]([VersionTimeStamp]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_Content_Control_Blog_URL] ON [dbo].[SLCMS_Site_0_Content_Control_Blog]([BlogURL]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Content_Control_Document] ADD 
	CONSTRAINT [DF_SLCMS_Content_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_Document_Content_flag_CurrentVersion] DEFAULT (0) FOR [Version],
	CONSTRAINT [DF_SLCMS_Content_Control_Document_ContentTypeID] DEFAULT (1) FOR [ContentTypeID],
	CONSTRAINT [DF_SLCMS_Document_Content_DocID] DEFAULT (0) FOR [DocID],
	CONSTRAINT [DF_SLCMS_Document_Content_ContainerID] DEFAULT (1) FOR [ContainerID],
	CONSTRAINT [DF_SLCMS_Content_Control_Document_ContentID] DEFAULT (0) FOR [ContentID],
	CONSTRAINT [DF_SLCMS_Content_Control_Document_EditMode] DEFAULT ('WYSIWYG') FOR [EditorMode],
	CONSTRAINT [DF_SLCMS_Content_Control_Document_flag_CurrentVersion] DEFAULT (0) FOR [flag_LiveVersion],
	CONSTRAINT [DF_SLCMS_Content_Control_Document_UserID_EditedBy] DEFAULT (0) FOR [UserID_EditedBy],
	CONSTRAINT [DF_SLCMS_Content_Control_Document_UserID_PublishedBy] DEFAULT (0) FOR [UserID_PublishedBy]
GO

 CREATE  INDEX [IX_SLCMS_Content_ContainerName] ON [dbo].[SLCMS_Site_0_Content_Control_Document]([ContainerName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_Document_Content_1] ON [dbo].[SLCMS_Site_0_Content_Control_Document]([VersionTimeStamp]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Content_Control_Object] ADD 
	CONSTRAINT [DF_SLCMS_Content_Control_Objectx_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_Content_Control_Objectx_Version] DEFAULT (0) FOR [Version],
	CONSTRAINT [DF_SLCMS_Content_Control_Objectx_flag_LiveVersion] DEFAULT (0) FOR [flag_LiveVersion]
GO

 CREATE  INDEX [IX_SLCMS_Content_Control_Object] ON [dbo].[SLCMS_Site_0_Content_Control_Object]([ItemID]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_Content_Control_Object_1] ON [dbo].[SLCMS_Site_0_Content_Control_Object]([Version], [ItemID]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Object_Data_Data] ADD 
	CONSTRAINT [DF_SLShop_Object_Data_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Object_Data_Definition] ADD 
	CONSTRAINT [DF_SLShop_Category1_Definitions_RepID] DEFAULT (newid()) FOR [RepID]
GO

 CREATE  INDEX [IX_SLShop_Category0_Definitions] ON [dbo].[SLCMS_Site_0_Object_Data_Definition]([FieldName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Object_Data_Images] ADD 
	CONSTRAINT [DF_SLCMS_Object_Image_Data_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Object_Description] ADD 
	CONSTRAINT [DF_SLShop_Category1_Description_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLShop_Category_Description_DO] DEFAULT (0) FOR [DO]
GO

 CREATE  INDEX [IX_SLShop_Category0_Description] ON [dbo].[SLCMS_Site_0_Object_Description]([ShortDescription]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Object_PhotoGalleries] ADD 
	CONSTRAINT [DF_SLCMS_Object_PhotoGalleries_RepID] DEFAULT (newid()) FOR [RepID]
GO

 CREATE  INDEX [IX_SLCMS_Object_PhotoGalleries] ON [dbo].[SLCMS_Site_0_Object_PhotoGalleries]([PhotoGalleryName]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Object_Shops] ADD 
	CONSTRAINT [DF_SLCMS_Object_Shops_RepID] DEFAULT (newid()) FOR [RepID]
GO

 CREATE  INDEX [IX_SLCMS_Object_Shops] ON [dbo].[SLCMS_Site_0_Object_Shops]([ShopName]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_PageStructure] ADD 
	CONSTRAINT [DF_SLCMS_PageStructure_DefaultDocID] DEFAULT (0) FOR [DefaultDocID],
	CONSTRAINT [DF_SLCMS_Document_Structure_DO] DEFAULT (0) FOR [DO],
	CONSTRAINT [DF_SLCMS_Document_Structure_HasContent] DEFAULT (1) FOR [HasContent],
	CONSTRAINT [DF_SLCMS_Document_Structure_HasChild] DEFAULT (0) FOR [IsParent],
	CONSTRAINT [DF_SLCMS_PageStructure_HasChildren] DEFAULT (0) FOR [Children],
	CONSTRAINT [DF_SLCMS_Document_Structure_Hidden] DEFAULT (0) FOR [Hidden],
	CONSTRAINT [DF_SLCMS_PageStructure_IsHomePage] DEFAULT (0) FOR [IsHomePage],
	CONSTRAINT [DF_SLCMS_Document_Structure_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_Roles] ADD 
	CONSTRAINT [DF_SLCMS_Roles_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_Roles_Role_HomeDocID] DEFAULT (0) FOR [Role_HomeDocID],
	CONSTRAINT [DF_SLCMS_Roles_DO] DEFAULT (0) FOR [DO]
GO

ALTER TABLE [dbo].[SLCMS_Site_0_wiki_LabelMapping] ADD 
	CONSTRAINT [DF_SLCMS_wiki_LabelMapping_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_wiki_LabelMapping_WikiID] DEFAULT (0) FOR [WikiID],
	CONSTRAINT [DF_SLCMS_wiki_LabelMapping_flag_CurrentLabel] DEFAULT (1) FOR [flag_CurrentLabel]
GO

ALTER TABLE [dbo].[SLCMS_System_Admin_UserDetails] ADD 
	CONSTRAINT [DF_SLCMS_System_Admin_Users_Global_RoleValue] DEFAULT (0) FOR [Global_RoleValue],
	CONSTRAINT [DF_SLCMS_System_Admin_Users_Global_RoleBits] DEFAULT ('00000000000000000000000000000000') FOR [Global_RoleBits],
	CONSTRAINT [DF_SLCMS_System_Admin_Users_User_Active] DEFAULT (0) FOR [User_Active],
	CONSTRAINT [DF_SLCMS_System_Admin_Users_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_System_Admin_UserRoles] ADD 
	CONSTRAINT [DF_SLCMS_System_Admin_UserRoles_RoleBits] DEFAULT ('00000000000000000000000000000000') FOR [RoleBits],
	CONSTRAINT [DF_SLCMS_System_Admin_UserRoles_RoleValue] DEFAULT (0) FOR [RoleValue],
	CONSTRAINT [DF_SLCMS_System_Admin_UserRoles_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_System_PortalControl] ADD 
	CONSTRAINT [DF_SLCMS_System_PortalControl_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_System_PortalControl_SiteActive] DEFAULT (1) FOR [SubSiteActive],
	CONSTRAINT [DF_SLCMS_System_PortalControl_DO] DEFAULT (0) FOR [DO]
GO

 CREATE  INDEX [IX_SLCMS_System_PortalControl] ON [dbo].[SLCMS_System_PortalControl]([SubSiteID]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_System_PortalControl_1] ON [dbo].[SLCMS_System_PortalControl]([SubSiteShortName]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_System_PortalParentDocs] ADD 
	CONSTRAINT [DF_SLCMS_System_PortalParentDocs_RepID] DEFAULT (newid()) FOR [RepID]
GO

 CREATE  INDEX [IX_SLCMS_System_PortalParentDocs] ON [dbo].[SLCMS_System_PortalParentDocs]([SubSiteID]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_SLCMS_System_PortalParentDocs_1] ON [dbo].[SLCMS_System_PortalParentDocs]([ParentDocID]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SLCMS_System_PortalURLs] ADD 
	CONSTRAINT [DF_SLCMS_System_PortalURLs_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_System_PortalURLs_DO] DEFAULT (0) FOR [DO]
GO

ALTER TABLE [dbo].[SLCMS_System_VersionControl] ADD 
	CONSTRAINT [DF_SLCMS_System_VersionControl_flag_ActiveVersion] DEFAULT (0) FOR [flag_ActiveVersion],
	CONSTRAINT [DF_SLCMS_System_VersionControl_VersionNumber_Full] DEFAULT (0) FOR [VersionNumber_Full],
	CONSTRAINT [DF_SLCMS_System_VersionControl_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_Type_Content] ADD 
	CONSTRAINT [DF_SLCMS_Type_Content_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_SLCMS_Type_Content_DO] DEFAULT (0) FOR [DO]
GO

ALTER TABLE [dbo].[SLCMS_Type_Document] ADD 
	CONSTRAINT [DF_SLCMS_DocumentType_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_Type_Template] ADD 
	CONSTRAINT [DF_SLCMS_TemplateType_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[SLCMS_Type_User_StaffRoles] ADD 
	CONSTRAINT [DF_SLCMS_Users_Roles_User_RoleNumber] DEFAULT (0) FOR [User_RoleBits],
	CONSTRAINT [DF_SLCMS_Users_RoleTypes_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[Stats_PacketStore] ADD 
	CONSTRAINT [DF_Stats_PacketStore_RepID] DEFAULT (newid()) FOR [RepID]
GO

 CREATE  INDEX [IX_Stats_PacketStore] ON [dbo].[Stats_PacketStore]([PacketName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

ALTER TABLE [dbo].[theThread_Links] ADD 
	CONSTRAINT [DF_theThrtead_links_RepID] DEFAULT (newid()) FOR [RepID]
GO

ALTER TABLE [dbo].[theThread_Matrix] ADD 
	CONSTRAINT [DF_theThread_Matrix_RepID] DEFAULT (newid()) FOR [RepID],
	CONSTRAINT [DF_theThread_Matrix_ThreadID_Left] DEFAULT (0) FOR [ThreadID_Left],
	CONSTRAINT [DF_theThread_Matrix_ThreadID_Right] DEFAULT (0) FOR [ThreadID_Right]
GO

 CREATE  INDEX [IX_theThread_Matrix] ON [dbo].[theThread_Matrix]([ThreadID_Left]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

 CREATE  INDEX [IX_theThread_Matrix_1] ON [dbo].[theThread_Matrix]([ThreadID_Right]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

ALTER TABLE [dbo].[theThread_Sets] ADD 
	CONSTRAINT [DF_theThread_Links_RepID] DEFAULT (newid()) FOR [RepID]
GO

 CREATE  INDEX [IX_theThread_Sets_1] ON [dbo].[theThread_Sets]([TableName], [FieldName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO

