component {
    property name="googleSitemapService" inject="GoogleSitemapService";

    /**
     * Rebuilds xml sitemap for Google, ensuring that they are all up to date with the latest data
     * Runs around 3am every morning.
     *
     * @displayName Rebuild XML Sitemap
     * @schedule 0 04 03 * * *
     * @priority 50
     * @timeout  7200
     */
    private boolean function rebuildSitemap( event, rc, prc, logger ) {
        return googleSitemapService.rebuildSitemap( event=event, logger=arguments.logger ?: NullValue() );
    }
}