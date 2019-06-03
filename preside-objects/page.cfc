component {
	property name="sitemap_priority"    type="string"  dbtype="varchar" maxLength="10" required=false default="inherit" enum="sitemapPriority";
	property name="sitemap_change_freq" type="string"  dbtype="varchar" maxLength="10" required=false default="inherit" enum="sitemapChangeFreq";
}