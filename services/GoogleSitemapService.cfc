/**
 * @singleton
 * @presideService
 */
component {

	/**
	 * @siteService.inject     siteService
	 * @siteTreeService.inject siteTreeService
	 */

	public function init( required any siteService, required any siteTreeService ){
		_setSiteService( arguments.siteService );
		_setSiteTreeService( arguments.siteTreeService );

		return this;
	}

	public boolean function rebuildSitemaps( any logger ) {
		var haveLogger = arguments.keyExists( "logger" );
		var canInfo    = haveLogger && arguments.logger.canInfo();
		var canError   = haveLogger && arguments.logger.canError();
		var sites      = _getSiteService().listSites();

		for( var site in sites ) {
			if ( $helpers.isTrue( site.sitemap_exclude ) ) {
				if ( canInfo ) { arguments.logger.info( "Skipping sitemap for [#site.name#]" ); }
				continue;
			}

			if ( canInfo ) { arguments.logger.info( "Building sitemap for [#site.name#]" ); }

			var success = rebuildSitemap( siteId=site.id, logger=arguments.logger ?: nullValue() );
			if ( !success ) {
				return false;
			}
		}

		if ( canInfo ) { arguments.logger.info( "Finished." ); }

		return true;
	}

	public boolean function rebuildSitemap( required string siteId, any logger ) {
		var haveAccessPages = [];
		var pages           = _getSiteTreeService().getPagesForSiteMap(
			  siteId       = arguments.siteId
			, allowDrafts  = false
			, format       = "nestedArray"
			, useCache     = false
			, selectFields = [
				  "page.id"
				, "page.slug"
				, "page.datemodified"
				, "page.search_engine_access"
				, "page.access_restriction"
				, "page._hierarchy_slug"
				, "page.active"
				, "page.trashed"
				, "page.exclude_from_sitemap"
				, "page.sitemap_priority"
				, "page.sitemap_change_freq"
				, "page.embargo_date"
				, "page.expiry_date"
				, "page.parent_page"
			]
		);

		var inheritedSearchEngineRules     = {};
		var inheritedpageAccessRestriction = {};
		var inheritedPageSitemapPriority   = {};
		var inheritedPageSitemapChangeFreq = {};
		var livePage                       = false;
		var pageSearchEngineRule           = "";
		var pageAccessRestriction          = "";

		for( var page in pages ) {
			livePage              = _checkLivePage( active=page.active, trashed=page.trashed, exclude_from_sitemap=page.exclude_from_sitemap, embargo_date=page.embargo_date, expiry_date=page.expiry_date );
			pageSearchEngineRule  = page.search_engine_access ?: "";
			pageAccessRestriction = page.access_restriction   ?: "";

			if ( page.search_engine_access=="inherit" ) {
				if ( !structKeyExists( inheritedSearchEngineRules, page.parent_page ) ) {
					pageSearchEngineRule = _getSearchEngineRulesForPage( arguments.siteId, page.id ).search_engine_access;
					inheritedSearchEngineRules[ page.parent_page ] = pageSearchEngineRule;
				} else {
					pageSearchEngineRule = inheritedSearchEngineRules[ page.parent_page ];
				}
			}

			if ( page.access_restriction=="inherit" ) {
				if ( !structKeyExists( inheritedpageAccessRestriction, page.parent_page ) ) {
					pageAccessRestriction = _getSiteTreeService().getAccessRestrictionRulesForPage( page.id ).access_restriction;
					inheritedpageAccessRestriction[ page.parent_page ] = pageAccessRestriction;
				} else {
					pageAccessRestriction = inheritedpageAccessRestriction[ page.parent_page ];
				}
			}

			if ( page.sitemap_priority=="inherit" ) {
				if ( !structKeyExists( inheritedPageSitemapPriority, page.parent_page ) ) {
					page.sitemap_priority = _getSitemapPriorityForPage( arguments.siteId, page.id );
					inheritedPageSitemapPriority[ page.parent_page ] = page.sitemap_priority;
				} else {
					page.sitemap_priority = inheritedPageSitemapPriority[ page.parent_page ];
				}
			}

			if ( page.sitemap_change_freq=="inherit" ) {
				if ( !structKeyExists( inheritedPageSitemapChangeFreq, page.parent_page ) ) {
					page.sitemap_change_freq = _getSitemapChangeFreqForPage( arguments.siteId, page.id );
					inheritedPageSitemapChangeFreq[ page.parent_page ] = page.sitemap_change_freq;
				} else {
					page.sitemap_change_freq = inheritedPageSitemapChangeFreq[ page.parent_page ];
				}
			}

			if ( pageSearchEngineRule=="allow" && pageAccessRestriction!="full" && livePage ) {
				haveAccessPages.append( _getSitemapAttributesForPage( arguments.siteId, page ) );
			}

			if ( page.hasChildren ) {
				_addChildPages(
					  siteId                   = arguments.siteId
					, haveAccessPages          = haveAccessPages
					, childPages               = page.children
					, parentSearchEngineAccess = pageSearchEngineRule
					, parentAccessRestriction  = pageAccessRestriction
					, parentSitemapPriority    = page.sitemap_priority
					, parentSitemapChangeFreq  = page.sitemap_change_freq
				);
			}
		}

		$announceInterception( "postPrepareXmlSitemapPages", { siteId=arguments.siteId, pages=haveAccessPages, logger=arguments.logger ?: nullvalue() } );

		return _buildSitemapFile( siteId=arguments.siteId, pages=haveAccessPages, logger=arguments.logger ?: nullvalue() );
	}

	private function _buildSitemapFile( required string siteId, required array pages, any logger ) {
		var counter     = 1;
		var sitemap     = [];
		var haveLogger  = arguments.keyExists( "logger" );
		var canInfo     = haveLogger && arguments.logger.canInfo();
		var canError    = haveLogger && arguments.logger.canError();
		var newline     = chr( 10 ) & chr( 13 );
		var loc         = "";
		var lastmod     = "";
		var priority    = "";
		var changeFreq  = "";
		var filename    = _getSitemapFilename( arguments.siteId );

		if ( canInfo ) { arguments.logger.info( "Starting to build XML sitemap for [#ArrayLen(arguments.pages)#] pages" ); }

		sitemap.append( '<?xml version="1.0" encoding="UTF-8"?>' );
		sitemap.append( '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' );

		for ( var page in arguments.pages ) {
			loc        = page.loc;
			lastmod    = DateFormat( page.lastmod, "yyyy-mm-dd" );
			priority   = _getPriorityRange( page.priority ?: "" );
			changeFreq = Len( page.changeFreq ?: "" ) ? page.changeFreq : "always";

			sitemap.append( "  <url>" );
			sitemap.append( "    <loc>#xmlFormat( loc )#</loc>" );
			sitemap.append( "    <lastmod>#lastmod#</lastmod>" );
			sitemap.append( "    <changefreq>#changeFreq#</changefreq>" );
			sitemap.append( "    <priority>#priority#</priority>" );
			sitemap.append( "  </url>" );

			counter++;
			if ( counter % 100 == 0 || counter == arguments.pages.len() ) {
				if ( canInfo ) { arguments.logger.info( "Processed #counter# pages..." ); }
			}
		}

		sitemap.append( "</urlset>" );

		try {
			var content = sitemap.toList( newline );
			FileWrite( expandPath( "/" & filename ), content );
			$announceInterception( "postWriteXmlSitemapFile", { filename="/#filename#", content=content } );
		} catch ( e ) {
			if ( canError ) { arguments.logger.error( "There's a problem creating #filename# file. Message [#e.message#], details: [#e.detail#]."); }
			return false;
		}

		if ( canInfo ) { arguments.logger.info( "Successfully created #filename#." ); }
		return true;
	}

	private struct function _getSitemapAttributesForPage( required string siteId, required struct page ) {
		var result        = {};
		var event         = $getRequestContext();
		var siteRootUrl   = event.getSiteUrl( arguments.siteId );

		result.loc        = siteRootUrl.reReplace( "/$", "" ) & page._hierarchy_slug.reReplace( "(.)/$", "\1.html" );
		result.lastmod    = page.datemodified;
		result.priority   = page.sitemap_priority ?: "";
		result.changeFreq = page.sitemap_change_freq ?: "";

		return result;
	}

	private struct function _getSearchEngineRulesForPage( required string siteId, required string pageId ) {
		var page = _getSiteTreeService().getPage(
			  site         = arguments.siteId
			, id           = arguments.pageId
			, selectFields = [ "id", "parent_page", "search_engine_access" ]
		);

		if ( !page.recordCount ) {
			return {
				search_engine_access = "allow"
			};
		}
		if ( !Len( Trim( page.search_engine_access ?: "" ) ) || page.search_engine_access == "inherit"   ) {
			if ( Len( Trim( page.parent_page ) ) ) {
				return _getSearchEngineRulesForPage( arguments.siteId, page.parent_page );
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

	private string function _getSitemapPriorityForPage( required string siteId, required string pageId ) {
		var page = _getSiteTreeService().getPage(
			  site         = arguments.siteId
			, id           = arguments.pageId
			, selectFields = [ "id", "parent_page", "sitemap_priority" ]
		);

		if ( !page.recordCount ) {
			return "normal";
		}
		if ( !Len( Trim( page.sitemap_priority ?: "" ) ) || page.sitemap_priority == "inherit"   ) {
			if ( Len( Trim( page.parent_page ) ) ) {
				return _getSitemapPriorityForPage( arguments.siteId, page.parent_page );
			} else {
				return "normal";
			}
		}

		return page.sitemap_priority;
	}

	private string function _getSitemapChangeFreqForPage( required string siteId, required string pageId ) {
		var page = _getSiteTreeService().getPage(
			  site         = arguments.siteId
			, id           = arguments.pageId
			, selectFields = [ "id", "parent_page", "sitemap_change_freq" ]
		);

		if ( !page.recordCount ) {
			return "always";
		}
		if ( !Len( Trim( page.sitemap_change_freq ?: "" ) ) || page.sitemap_change_freq == "inherit"   ) {
			if ( Len( Trim( page.parent_page ) ) ) {
				return _getSitemapChangeFreqForPage( arguments.siteId, page.parent_page );
			} else {
				return "always";
			}
		}

		return page.sitemap_change_freq;
	}

	private function _addChildPages(
		  required string siteId
		, required array  haveAccessPages
		, required array  childPages
		,          string parentSearchEngineAccess
		,          string parentAccessRestriction
		,          string parentSitemapPriority
		,          string parentSitemapChangeFreq
	) {
		var livePage              = false;
		var pageSearchEngineRule  = "";
		var pageAccessRestriction = "";

		for( var childPage in arguments.childPages ) {
			livePage                      = _checkLivePage( active=childPage.active, trashed=childPage.trashed, exclude_from_sitemap=childPage.exclude_from_sitemap, embargo_date=childPage.embargo_date, expiry_date=childPage.expiry_date );
			pageSearchEngineRule          = childPage.search_engine_access == "inherit" ? arguments.parentSearchEngineAccess : childPage.search_engine_access;
			pageAccessRestriction         = childPage.access_restriction   == "inherit" ? arguments.parentAccessRestriction  : childPage.access_restriction;
			childPage.sitemap_priority    = childPage.sitemap_priority     == "inherit" ? arguments.parentSitemapPriority    : childPage.sitemap_priority;
			childPage.sitemap_change_freq = childPage.sitemap_change_freq  == "inherit" ? arguments.parentSitemapChangeFreq  : childPage.sitemap_change_freq;

			if ( pageSearchEngineRule=="allow" && pageAccessRestriction!="full" && livePage ) {
				arguments.haveAccessPages.append( _getSitemapAttributesForPage( arguments.siteId, childPage ) );
			}

			if ( childPage.hasChildren ) {
				_addChildPages(
					  siteId                   = arguments.siteId
					, haveAccessPages          = arguments.haveAccessPages
					, childPages               = childPage.children
					, parentSearchEngineAccess = pageSearchEngineRule
					, parentAccessRestriction  = pageAccessRestriction
					, parentSitemapPriority    = childPage.sitemap_priority
					, parentSitemapChangeFreq  = childPage.sitemap_change_freq
				);
			}
		}
	}

	private boolean function _checkLivePage(
		  string active
		, string trashed
		, string exclude_from_sitemap
		, string embargo_date
		, string expiry_date
	) {
		if ( arguments.active == 0 || arguments.trashed == "1" || arguments.exclude_from_sitemap == "1" ) {
			return false;
		}

		var isEmbargoed = isDate( arguments.embargo_date ) && now() < arguments.embargo_date;
		var isExpired   = isDate( arguments.expiry_date  ) && now() > arguments.expiry_date;

		if ( isEmbargoed || isExpired ) {
			return false;
		}

		return true;
	}

	private string function _getPriorityRange( string priority ){
		var priority = arguments.priority ?: "normal";

		switch( priority ){
			case "important":
				return "1.0";
				break;
			case "high":
				return "0.8";
				break;
			case "normal":
				return "0.5";
				break;
			case "low":
				return "0.3";
				break;
			default:
				return "0.5";
		}

		return "0.5";
	}

	private string function _getSitemapFilename( required string siteId ) {
		var site = _getSiteService().getSite( arguments.siteId );
		if ( len( site.sitemap_suffix ) ) {
			return "sitemap-#site.sitemap_suffix#.xml";
		}

		return "sitemap.xml";
	}

// GETTERS AND SETTERS
	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}

	private any function _getSiteTreeService() {
		return _siteTreeService;
	}
	private void function _setSiteTreeService( required any siteTreeService ) {
		_siteTreeService = arguments.siteTreeService;
	}

}