component extends="preside.system.services.siteTree.SiteTreeService" {

	public any function getPagesForSiteMap(
		  required string  siteId
		,          boolean trash        = false
		,          array   selectFields = []
		,          string  format       = "query"
		,          boolean useCache     = true
		,          string  rootPageId   = ""
		,          numeric maxDepth     = -1

	) {
		var tree     = "";
		var rootPage = "";
		var filter   = "page.trashed = :trashed";
		var maxDepth = arguments.maxDepth;
		var args = {
			  orderBy      = "page._hierarchy_sort_order"
			, filter       = filter
			, filterParams = { trashed = arguments.trash }
			, useCache     = arguments.useCache
			, groupBy      = "page.id"
			, tenantIds    = { site=arguments.siteId }
		};

		if ( ArrayLen( arguments.selectFields ) ) {
			args.selectFields = arguments.selectFields;
			if ( format eq "nestedArray" and not args.selectFields.find( "_hierarchy_depth" ) and not args.selectFields.find( "page._hierarchy_depth" ) ) {
				ArrayAppend( args.selectFields, "page._hierarchy_depth" );
			}

			if ( !args.selectFields.find( "page._hierarchy_sort_order" ) ) {
				args.selectFields.append( "page._hierarchy_sort_order" );
			}
		}

		if ( Len( Trim( arguments.rootPageId ) ) ) {
			rootPage = getPage( id=arguments.rootPageId, selectFields=[ "_hierarchy_child_selector", "_hierarchy_depth" ] );

			args.filter &= " and page._hierarchy_lineage like :_hierarchy_lineage";
			args.filterParams._hierarchy_lineage = rootPage._hierarchy_child_selector;

			if ( maxDepth >= 0 && !isNull( rootPage._hierarchy_depth ) && isNumeric( rootPage._hierarchy_depth ) ) {
				maxDepth += rootPage._hierarchy_depth+1;
			}
		}

		if ( maxDepth >= 0 ) {
			args.filter &= " and page._hierarchy_depth <= :_hierarchy_depth";
			args.filterParams._hierarchy_depth = maxDepth;
		}


		tree = _getPObj().selectData( argumentCollection=args );

		if ( arguments.format eq "nestedArray" ) {
			if ( Len( Trim( arguments.rootPageId ) ) ) {
				return _treeQueryToNestedArray( tree, rootPage );
			}
			return _treeQueryToNestedArray( tree );
		}

		return tree;
	}
}