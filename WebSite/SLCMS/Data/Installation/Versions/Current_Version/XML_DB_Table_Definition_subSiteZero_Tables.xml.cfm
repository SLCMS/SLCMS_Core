<?xml version="1.0" encoding="UTF-8"?>
<tables>
	<table name="slcms_site_0_content_content">
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="EntryID" Increment="true" primarykey="true"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="contentid" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="contentchunk" length="4000" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="contentchunknumber" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_bit" columnname="flag_currentversion" default="1" precision="1" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="contenttypeid" default="1" precision="10" scale="2"/>
	</table>
	<table name="slcms_site_0_blog_categories">
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="EntryID" Increment="true" primarykey="true"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="blogid" default="0" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="blogcategoryid" default="1" precision="10" primarykey="true" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="blogcategorytitle" length="50" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="blogcategorynavname" length="50" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="blogcategoryurlname" length="50" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="blogcategorydescription" length="255" precision="12" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="version" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_date" columnname="versiontimestamp" precision="23" scale="3"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="do" default="0" precision="10" scale="2"/>
	</table>
	<table name="slcms_site_0_content_control_document">
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="version" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_date" columnname="versiontimestamp" precision="23" scale="3"/>
		<field allownulls="yes" cf_datatype="cf_sql_char" columnname="contenthandle" length="35" precision="12" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="contenttypeid" default="1" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="docid" default="0" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="containerid" default="1" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="containername" length="50" precision="12" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="contentid" default="0" precision="10" primarykey="true" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="editormode" default="'wysiwyg'" length="50" precision="12" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_bit" columnname="flag_liveversion" default="0" precision="1" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="userid_editedby" default="0" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="userid_publishedby" default="0" precision="10" scale="2"/>
	</table>
	<table name="slcms_site_0_admin_userroles">
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="userid" precision="10" primarykey="true" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="siteid" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="moduleid" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_char" columnname="rolebits" default="'00000000000000000000000000000000'" length="32" precision="12" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="rolevalue" default="0" precision="10" scale="2"/>
	</table>
	<table name="slcms_site_0_blog_blogs">
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="EntryID" Increment="true" primarykey="true"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="blogid" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="blogtitle" length="50" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="blognavname" length="50" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="blogurlname" length="50" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="blogdescription" length="255" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="do" default="0" precision="10" scale="2"/>
	</table>
	<table name="slcms_site_0_admin_userdetails">
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="staffId" default="0" precision="10" primarykey="true" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="staff_SignIn" length="64" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="staff_password" length="64" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="staff_FirstName" length="64" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="staff_LastName" length="64" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="staff_eddress" length="255" precision="12" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_char" columnname="global_rolebits" default="'00000000000000000000000000000000'" length="32" precision="12" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="global_rolevalue" default="0" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_bit" columnname="user_active" default="0" precision="1" scale="2"/>
	</table>
	<table name="slcms_site_0_pagestructure">
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="docid" precision="10" primarykey="true" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="parentid" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="defaultdocid" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="doctype" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="param1" length="128" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="param2" length="128" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="param3" length="128" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="param4" length="128" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="param5" length="128" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="do" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_bit" columnname="hascontent" default="1" precision="1" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_bit" columnname="isparent" default="0" precision="1" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="children" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="hidden" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="navname" length="128" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="urlname" length="128" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="urlnameencoded" length="255" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_bit" columnname="ishomepage" default="0" precision="1" scale="2"/>
	</table>
	<table name="slcms_site_0_wiki_labelmapping">
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="docid" precision="10" primarykey="true" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="wikiid" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="label" length="50" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_date" columnname="datecreated" precision="23" scale="3"/>
		<field allownulls="no" cf_datatype="cf_sql_bit" columnname="flag_currentlabel" default="1" precision="1" scale="2"/>
	</table>
	<table name="slcms_site_0_content_control_object">
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="itemid" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="name" length="128" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="imageid" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="productid" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_date" columnname="versiontimestamp" precision="23" scale="3"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="version" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_char" columnname="itemhandle" length="35" precision="12" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="contentid" precision="10" primarykey="true" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_bit" columnname="flag_liveversion" default="0" precision="1" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="userid_editedby" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="userid_publishedby" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="shortdescription" length="255" precision="12" scale="2"/>
	</table>
	<table name="slcms_site_0_content_control_blog">
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="version" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_date" columnname="versiontimestamp" precision="23" scale="3"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="blogid" default="0" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="blogcategoryid" default="1" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="blogentryid" default="0" precision="10" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_date" columnname="entrydate" precision="23" scale="3"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="contentid" default="0" precision="10" primarykey="true" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="summary" length="255" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="title" length="255" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="blogurl" length="255" precision="12" scale="2"/>
	</table>
	<table name="slcms_site_0_roles">
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="roleid" precision="10" primarykey="true" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_varchar" columnname="role_description" length="50" precision="12" scale="2"/>
		<field allownulls="yes" cf_datatype="cf_sql_integer" columnname="role_defaultpermissions" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="role_homedocid" default="0" precision="10" scale="2"/>
		<field allownulls="no" cf_datatype="cf_sql_integer" columnname="do" default="0" precision="10" scale="2"/>
	</table>
</tables>
