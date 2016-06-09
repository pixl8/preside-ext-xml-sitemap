/**
 * @singleton
 * @presideService
 */
component {

	/**
	 * @siteTreeService.inject siteTreeService
	 */

	public function init( required any siteTreeService ) output=false{
		_setSiteTreeService(   arguments.siteTreeService     );

		return this;
	}

	public boolean function rebuildSitemap( any logger ) {
		var haveAccessPages = [];
		var pages           = $getPresideObject( 'page' ).selectData(
			  selectFields  = [ "page.id", "page.slug", "page.datemodified", "page.search_engine_access", "page.access_restriction" ]
			, filter        = "page.search_engine_access != 'block' AND page.access_restriction NOT IN ( 'partial', 'full' ) AND page.exclude_from_sitemap = 0"
			, savedFilters  = [ "livePages" ]
			, orderBy       = "page._hierarchy_slug"
		);

		for( var page in pages ){
			var pageAccessRestriction = _getSiteTreeService().getAccessRestrictionRulesForPage( page.id );
			var pageSearchEngineRule  = _getSearchEngineRulesForPage( page.id );

			if( pageSearchEngineRule.search_engine_access=="allow" && pageAccessRestriction.access_restriction=="none" ){
				haveAccessPages.append( page );
			}
		}

		return _buildSitemapFile( pages=haveAccessPages, logger=arguments.logger );
	}

	private function _buildSitemapFile( required array pages, any logger ) {
		var counter       = 1;
		var googleSitemap = xmlNew();

		googleSitemap.xmlRoot = xmlElemNew( googleSitemap, "urlset" );
		googleSitemap.xmlRoot.XmlAttributes.xmlns = "http://www.sitemaps.org/schemas/sitemap/0.9"

		for ( var page in arguments.pages ){
			var elemUrl        = xmlElemNew( googleSitemap, "url"        );
			var elemLoc        = XmlElemNew( googleSitemap, "loc"        );
			var elemLsatMod    = XmlElemNew( googleSitemap, "lastmod"    );
			var elemChangeFreq = XmlElemNew( googleSitemap, "changefreq" );

			elemLoc.XmlText        = _getRequestContext().buildLink( page=page.id );
			elemLsatMod.XmlText    = DateFormat( page.datemodified, "yyyy-mm-dd" );
			elemChangeFreq.XmlText = "always";

			elemUrl.XmlChildren.append( elemLoc        );
			elemUrl.XmlChildren.append( elemLsatMod    );
			elemUrl.XmlChildren.append( elemChangeFreq );

			googleSitemap.xmlRoot.XmlChildren[counter++] = elemUrl;
		}

		try{
			FileWrite( expandPath('/sitemap.xml'), googleSitemap );
		} catch ( e ){
			arguments.logger.error( "There's a problem creating sitemap.xml file. Message [#e.message#], details: [#e.detail#].");
			return false;
		}

		arguments.logger.info( "Successfully created sitemap.xml." );
		return true;
	}

	private struct function _getSearchEngineRulesForPage( required string pageId ) {
		var page = _getSiteTreeService().getPage( id=arguments.pageId, selectFields=[ "id", "parent_page", "search_engine_access" ] );

		if ( !page.recordCount ) {
			return {
				search_engine_access = "allow"
			};
		}
		if ( !Len( Trim( page.search_engine_access ?: "" ) ) || page.search_engine_access == "inherit"   ) {
			if ( Len( Trim( page.parent_page ) ) ) {
				return _getSearchEngineRulesForPage( page.parent_page );
			} else {
				return {
					search_engine_access = "allow"
				};
			}
		}

		return {
			search_engine_access = page.search_engine_access
		};
	}

	private any function _getRequestContext() {
		return $getColdbox().getRequestService().getContext();
	}

// GETTERS AND SETTERS

	private any function _getSiteTreeService() {
		return _siteTreeService;
	}
	private void function _setSiteTreeService( required any siteTreeService ) {
		_siteTreeService = arguments.siteTreeService;
	}

}