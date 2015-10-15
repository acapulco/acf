/**
 *   Extends the DataSource.Connection class to enable
 *   Salesforce to sync the external system’s metadata schema
 *   and to handle queries and searches of the external data.
 **/
global class DriveDataSourceConnection extends
    DataSource.Connection {
    private DataSource.ConnectionParams connectionInfo;

    /**
     *   Constructor for DriveDataSourceConnection.
     **/
    global DriveDataSourceConnection(
    DataSource.ConnectionParams connectionInfo) {
    this.connectionInfo = connectionInfo;
    }

    /**
     *   Called when the administrator clicks “Validate and Sync”
     *   in the user interface for the external data source.
     **/
    override global List<DataSource.Table> sync() {
        List<DataSource.Table> tables =
        new List<DataSource.Table>();
    List<DataSource.Column> columns;
    columns = new List<DataSource.Column>();
    columns.add(DataSource.Column.text('title', 255));
    columns.add(DataSource.Column.text('description',255));
    columns.add(DataSource.Column.text('createdDate',255));
    columns.add(DataSource.Column.text('modifiedDate',255));
    columns.add(DataSource.Column.url('selfLink'));
    columns.add(DataSource.Column.url('DisplayUrl'));
    columns.add(DataSource.Column.text('ExternalId',255));
    tables.add(DataSource.Table.get('googleDrive','title',
        columns));
    return tables;
    }

    /**
     *   Called to query and get results from the external
     *   system for SOQL queries, list views, and detail pages
     *   for an external object that’s associated with the
     *   external data source.
     *
     *   The queryContext argument represents the query to run
     *   against a table in the external system.
     *
     *   Returns a list of rows as the query results.
     **/
    override global DataSource.TableResult query(
    DataSource.QueryContext c){
    DataSource.Filter filter = c.tableSelection.filter;
    String url;
    if (filter != null) {
        String cName = filter.columnName;
        if (cName != null && cName.equals('ExternalId'))
            url = 'https://www.googleapis.com/drive/v2/'
            + 'files/' + filter.columnValue;
        else
            url = 'https://www.googleapis.com/drive/v2/'
            + 'files';
    } else {
        url = 'https://www.googleapis.com/drive/v2/'
            + 'files';
    }

    /**
     *   Filters, sorts, and applies limit and offset clauses.
     **/
    List<Map<String, Object>> rows =
        DataSource.QueryUtils.process(c, getData(url));
    return DataSource.TableResult.get(true, null,
        c.tableSelection.tableSelected, rows);
    }

    /**
     *   Called to do a full text search and get results from
     *   the external system for SOSL queries and Salesforce
     *   global searches.
     *
     *   The searchContext argument represents the query to run
     *   against a table in the external system.
     *
     *   Returns results for each table that the searchContext
     *   requested to be searched.
     **/
    override global List<DataSource.TableResult> search(
        DataSource.SearchContext c){
    List<DataSource.TableResult> results =
        new List<DataSource.TableResult>();

    for (Integer i =0; i< c.tableSelections.size();i++){
        String entity = c.tableSelections[i].tableSelected;
        String url = 'https://www.googleapis.com/drive/v2/files'+
            '?q=fullText+contains+\''+c.searchPhrase+'\'';
        results.add(DataSource.TableResult.get(
            true, null, entity, getData(url)));
        }

    return results;
    }

    /**
     *   Helper method to parse the data.
     *   The url argument is the URL of the external system.
     *   Returns a list of rows from the external system.
     **/

    public List<Map<String, Object>> getData(String url){
    HttpResponse response = getResponse(url);

    List<Map<String, Object>> rows =
        new List<Map<String, Object>>();

    Map<String, Object> m = (
        Map<String, Object>)JSON.deserializeUntyped(
        response.getBody());

    /**
     *   Checks errors.
     **/
    Map<String, Object> error =
        (Map<String, Object>)m.get('error');
    if (error!=null){
        List<Object> errorsList =
            (List<Object>)error.get('errors');
        Map<String, Object> errors =
            (Map<String, Object>)errorsList[0];
        String ms = (String)errors.get('message');
        throw new DataSource.OAuthTokenExpiredException(ms);
    }

    List<Object> fileItems=(List<Object>)m.get('items');
    if (fileItems != null){
        for (Integer i=0; i< fileItems.size(); i++){
            Map<String, Object> item =
                (Map<String, Object>)fileItems[i];
            rows.add(createRow(item));
        }
    } else {
        rows.add(createRow(m));
    }

    return rows;
    }

    /**
     *   Helper method to populate the External ID and Display
     *   URL fields on external object records based on the ‘id’
     *   value that’s sent by the external system.
     *
     *   The item argument maps to the data that
     *   represents a row.
     *
     *   Returns an updated map with the External ID and
     *   Display URL values.
     **/
    public Map<String, Object> createRow(
        Map<String, Object> item){
    Map<String, Object> row = new Map<String, Object>();
    for ( String key : item.keySet() ){
        if (key == 'id') {
            row.put('ExternalId', item.get(key));
        } else if (key=='selfLink'){
            row.put(key, item.get(key));
            row.put('DisplayUrl', item.get(key));
        } else {
        row.put(key, item.get(key));
        }
    }
    return row;
    }

    /**
     *   Helper method to make the HTTP GET call.
     *   The url argument is the URL of the external system.
     *   Returns the response from the external system.
     **/
    public HttpResponse getResponse(String url) {
    Http httpProtocol = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndPoint(url);
    request.setMethod('GET');
    request.setHeader('Authorization', 'Bearer '+
        this.connectionInfo.oauthToken);
    HttpResponse response = httpProtocol.send(request);
    return response;
    }
}