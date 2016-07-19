# PresideCMS Extension: XML Sitemap Extension

This is an extension for PresideCMS that will create `sitemap.xml` for all active pages

##Scheduled task

If using PresideCMS 10.6.x and below, Schedule Task Extension will need to be installed before XML Sitemap Extension will be able to run (ask about this in the PresideCMS slack channel!).

##.gitignore

The file, `sitemap.xml` will be generated by the scheduled task in your webroot. You should add a `.gitignore` rule to keep it out of your repository.

## Installation

Install the extension to your application via either of the methods detailed below (Git submodule / CommandBox) and then enable the extension by opening up the Preside developer console and entering:

	extension enable preside-ext-xml-sitemap
	reload all

### Git Submodule method
From the root of your application, type the following command:

	git submodule add https://github.com/pixl8/preside-ext-xml-sitemap.git application/extensions/preside-ext-xml-sitemap

### CommandBox (box.json) method
From the root of your application, type the following command:

	box install pixl8/preside-ext-xml-sitemap#v1.1.0

## Making your sitemap available to Google
There are two different ways to make your sitemap available to Google:

* [Submit it to Google using the Search Console Sitemaps tool](https://www.google.com/webmasters/tools/sitemap-list)

*OR*

* Insert the following line anywhere in your robots.txt file, specifying the path to your sitemap:

	`Sitemap: http://mydomain.com/sitemap.xml`
