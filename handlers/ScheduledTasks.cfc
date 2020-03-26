component {
    property name="googleSitemapService" inject="GoogleSitemapService";

    /**
     * Rebuilds xml sitemap for Google, ensuring that they are all up to date with the latest data
     * Runs around 3am every morning.
     *
     * @displayName Rebuild XML Sitemap
     * @schedule 0 04 03 * * *
     * @priority 50
     * @timeout  14400
     */
    private boolean function rebuildSitemap( event, rc, prc, logger ) {
        return googleSitemapService.rebuildSitemaps( logger=arguments.logger ?: NullValue() );
    }
}