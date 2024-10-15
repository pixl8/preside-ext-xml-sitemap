# Changelog

## v1.2.3

* Include partially restricted pages in sitemap

## v1.2.2

* [#13](https://github.com/pixl8/preside-ext-xml-sitemap/issues/13) - Announce interception point after writing to file

## v1.2.1

* Convert to github build system
* Add German i18n translations

## v1.2.0

* Change build/publish process
* Add 'postPrepareXmlSitemapPages' interception point to append custom pages to sitemap
* Add support for multiple sites

## v1.1.2

* Add default value to sitemap_priority

## v1.1.1

* Add ability to set sitemap changefreq on individual pages

## v1.1.0

* Add ability to set sitemap priority on individual pages


## v1.0.10

* Increase schedule task timeout
* Don't use cache for page query
* Build XML text manually for improved readabilty
* Don't add .html to URL if page is homepage
* Clarify checkLivePage() logic, improve var-scoping
* Code style formatting

## v1.0.9

* Use correct repo url in box.json

## v1.0.8

* Fixing up publishing process

## v1.0.7

* Boxifying the repo with automated publish

## v1.0.6

* Ensures repeated process is reduces to improve the speed

## v1.0.5

* couple of function name that was missed previously

## v1.0.4

* Amendment to function names
* Add missing arguemnt type in rebuildSitemap function
* Update backend service to improve performance when building sitemap

## v1.0.3

* Added instruction for submitting the sitemap / adding to robots.txt
* Updated typo for "last" in variable "elemLastMod"
* FIX for fileWrite throwing a `java.io.IOException` error `can't write down object of type [struct] to resource` - always ensure the outut is a string / simple value
* Add logger key exists checker before logging info and error message
* Add logger info when sitemap task is being run

## v1.0.1

* Add README.md
* Initial import of extension from Nelson's work
