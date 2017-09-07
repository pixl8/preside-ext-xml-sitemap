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

	public boolean function rebuildSitemap( any event, any logger ) {
		var haveAccessPages = [];
		var pages           = _getSiteTreeService().getPagesForSiteMap(
			selectFields  = [
				  "page.id"
				, "page.slug"
				, "page.datemodified"
				, "page.search_engine_access"
				, "page.access_restriction"
				, "page._hierarchy_slug"
				, "page.active"
				, "page.trashed"
				, "page.exclude_from_sitemap"
				, "page.embargo_date"
				, "page.expiry_date"
				, "page.parent_page"
			]
			, allowDrafts = false
			, format      = "nestedArray"
		);

		var inheritedSearchEngineRules     = {};
		var inheritedpageAccessRestriction = {};

		for( var page in pages ){
			var livePage              = checkLivePage( active=page.active, trashed=page.trashed, exclude_from_sitemap=page.exclude_from_sitemap, embargo_date=page.embargo_date, expiry_date=page.expiry_date );
			var pageSearchEngineRule  = page.search_engine_access ?: "";
			var pageAccessRestriction = page.access_restriction   ?: "";

			if( page.search_engine_access=="inherit" ){
				if( !structKeyExists( inheritedSearchEngineRules, page.parent_page ) ){
					pageSearchEngineRule = _getSearchEngineRulesForPage( page.id ).search_engine_access;
					inheritedSearchEngineRules[ page.parent_page ] = pageSearchEngineRule;
				}else{
					pageSearchEngineRule = inheritedSearchEngineRules[ page.parent_page ];
				}
			}

			if( page.access_restriction=="inherit" ){
				if( !structKeyExists( inheritedpageAccessRestriction, page.parent_page ) ){
					pageAccessRestriction = _getSiteTreeService().getAccessRestrictionRulesForPage( page.id ).access_restriction;
					inheritedpageAccessRestriction[ page.parent_page ] = pageAccessRestriction;
				}else{
					pageAccessRestriction = inheritedpageAccessRestriction[ page.parent_page ];
				}
			}

			if( pageSearchEngineRule=="allow" && pageAccessRestriction=="none" && livePage ){
				haveAccessPages.append( page );
			}

			if( page.hasChildren ){
				_addChildPages( haveAccessPages=haveAccessPages, childPages=page.children, parentSearchEngineAccess=pageSearchEngineRule, parentAccessRestriction=pageAccessRestriction );
			}
		}

		return _buildSitemapFile( pages=haveAccessPages, logger=arguments.logger, event=arguments.event );
	}

	private function _buildSitemapFile( required array pages, any logger, any event ) {
		var counter       = 1;
		var googleSitemap = xmlNew();
		var xmlSitemap    = "";
		var haveLogger    = arguments.keyExists( "logger" );
		var canInfo       = haveLogger && arguments.logger.canInfo();
		var canError      = haveLogger && arguments.logger.canError();
		var siteRootUrl   = arguments.event.getSiteUrl( arguments.event.getSite().id );

		googleSitemap.xmlRoot = xmlElemNew( googleSitemap, "urlset" );
		googleSitemap.xmlRoot.XmlAttributes.xmlns = "http://www.sitemaps.org/schemas/sitemap/0.9"

		if ( canInfo ) { arguments.logger.info( "Starting to rebuild XML sitemap for [#ArrayLen(arguments.pages)#] pages" ); }

		for ( var page in arguments.pages ){
			var elemUrl        = xmlElemNew( googleSitemap, "url"        );
			var elemLoc        = XmlElemNew( googleSitemap, "loc"        );
			var elemLastMod    = XmlElemNew( googleSitemap, "lastmod"    );
			var elemChangeFreq = XmlElemNew( googleSitemap, "changefreq" );

			elemLoc.XmlText        = siteRootUrl.reReplace("/$", "") & page._hierarchy_slug.reReplace("/$", ".html");
			elemLastMod.XmlText    = DateFormat( page.datemodified, "yyyy-mm-dd" );
			elemChangeFreq.XmlText = "always";

			elemUrl.XmlChildren.append( elemLoc        );
			elemUrl.XmlChildren.append( elemLastMod    );
			elemUrl.XmlChildren.append( elemChangeFreq );

			googleSitemap.xmlRoot.XmlChildren[counter++] = elemUrl;

			if( counter % 100 == 0 ){
				if ( canInfo ) { arguments.logger.info( "Processed 100 pages..." ); }
			}
		}

		try{
			xmlSitemap = IsSimpleValue( googleSitemap ) ? googleSiteMap : ToString( googleSiteMap );
			FileWrite( expandPath('/sitemap.xml'), xmlSitemap );
		} catch ( e ){
			if ( canError ) { arguments.logger.error( "There's a problem creating sitemap.xml file. Message [#e.message#], details: [#e.detail#]."); }
			return false;
		}

		if ( canInfo ) { arguments.logger.info( "Successfully created sitemap.xml." ); }
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

	private function _addChildPages( required array haveAccessPages, required array childPages, string parentSearchEngineAccess, string parentAccessRestriction ) {

		for( var currentChildPage in arguments.childPages ){
			var currentSearchEngineAccess  = currentChildPage.search_engine_access EQ "inherit" ? arguments.parentSearchEngineAccess : currentChildPage.search_engine_access;
			var currentAccessRestriction   = currentChildPage.access_restriction   EQ "inherit" ? arguments.parentAccessRestriction  : currentChildPage.access_restriction;
			var livePage                   = checkLivePage( active=currentChildPage.active, trashed=currentChildPage.trashed, exclude_from_sitemap=currentChildPage.exclude_from_sitemap, embargo_date=currentChildPage.embargo_date, expiry_date=currentChildPage.expiry_date );

			if( currentSearchEngineAccess=="allow" && currentAccessRestriction=="none" && livePage ){
				arguments.haveAccessPages.append( currentChildPage );
			}

			if( currentChildPage.hasChildren ){
				_addChildPages( haveAccessPages=arguments.haveAccessPages, childPages=currentChildPage.children, parentSearchEngineAccess=currentSearchEngineAccess, parentAccessRestriction=currentAccessRestriction );
			}
		}

	}

	private boolean function checkLivePage(
		  string active
		, string trashed
		, string exclude_from_sitemap
		, string embargo_date
		, string expiry_date
	) {

		if( arguments.active == 0 || arguments.trashed == "1" || arguments.exclude_from_sitemap == "1" ){
			return false;
		}

		if( ( isDate( arguments.embargo_date ?: "" ) && arguments.embargo_date GT now() ) || ( isDate( arguments.expiry_date ?: "" ) && arguments.expiry_date LT now() ) ){
			return false;
		}

		return true;
	}

// GETTERS AND SETTERS

	private any function _getSiteTreeService() {
		return _siteTreeService;
	}
	private void function _setSiteTreeService( required any siteTreeService ) {
		_siteTreeService = arguments.siteTreeService;
	}

}