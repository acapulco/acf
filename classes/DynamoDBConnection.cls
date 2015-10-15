/**
 *   Extends the DataSource.Connection class to enable
 *   Salesforce to sync the external system’s metadata schema
 *   and to handle queries and searches of the external data.
 **/
global class DynamoDBConnection extends DataSource.Connection {
	private DataSource.ConnectionParams connectionInfo;

	/**
	 *   Constructor for DynamoDBConnection.
	 **/
	global DynamoDBConnection(DataSource.ConnectionParams connectionInfo) {
		this.connectionInfo = connectionInfo;
	}

	/**
	 *   Called when the administrator clicks “Validate and Sync”
	 *   in the user interface for the external data source.
	 **/
	override global List<DataSource.Table> sync() {
		List<DataSource.Table> tables = new List<DataSource.Table>();

		List<DataSource.Column> columns;
		columns = new List<DataSource.Column>();
		columns.add(DataSource.Column.text('title',255));
		columns.add(DataSource.Column.textarea('detail'));
		columns.add(DataSource.Column.text('no', 2));
		columns.add(DataSource.Column.text('case_id', 8));
		columns.add(DataSource.Column.text('ExternalId', 10));
		columns.add(DataSource.Column.url('DisplayUrl'));
		tables.add(DataSource.Table.get('Cases','case_id',columns));

		return tables;
	}

	override global DataSource.TableResult query(DataSource.QueryContext c){
		DataSource.Filter filter = c.tableSelection.filter;

		DynamoDBClient client = new DynamoDBClient();
		AWSAccessResult aar;
		if (filter != null && filter.columnName != null && filter.columnName.equals('ExternalId')) {
			String[] key = String.valueOf(filter.columnValue).split('-');
			aar = client.getItem(
				'{"TableName": "cases", "Key": {"case_id": {"S": "' + key[0] + '"},"no":{"S":"' + key[1] + '"}}}');
		} else {
			aar = client.scan('{"TableName": "cases"}');
		}

		if(!aar.isSuccess()) {
			aar.outputResult();
			throw new DynamoDBException('System Error.');
		}

		List<Map<String, Object>> parsedRows = parseResponse(aar.res.getBody());

		system.debug(parsedRows);

		List<Map<String,Object>> filteredRows =
			DataSource.QueryUtils.filter(c, parsedRows);

		List<Map<String,Object>> sortedRows =
			DataSource.QueryUtils.sort(c, filteredRows);

		List<Map<String,Object>> limitedRows =
			DataSource.QueryUtils.applyLimitAndOffset(c, sortedRows);

		return DataSource.TableResult.get(c, limitedRows);
	}

	override global List<DataSource.TableResult> search(DataSource.SearchContext c){
		List<DataSource.TableResult> tableResults = new List<DataSource.TableResult>();

		CloudSearchClient client = new CloudSearchClient();
		AWSAccessResult aar =
			client.search('q=' + EncodingUtil.urlEncode(c.searchPhrase, 'UTF-8'), 'search-cases-v2hhtee7vt3frqenggaoelsrjy');

		if(!aar.isSuccess()) {
			aar.outputResult();
			throw new DynamoDBException('System Error.');
		}

		tableResults.add(
			DataSource.TableResult.get(c.tableSelections.get(0), parseResponse(aar.res.getBody())));
		return tableResults;
	}

	private List<Map<String, Object>> parseResponse(String response){
		List<Map<String, Object>> rows =
			new List<Map<String, Object>>();

		Map<String, Object> deserializedResponse =
			(Map<String, Object>) JSON.deserializeUntyped(response);

		// dynamoDB scan
		if(deserializedResponse.containsKey('Items')){
			List<Object> items = (List<Object>) deserializedResponse.get('Items');
			Integer itemSize = items.size();
			for(Integer i = 0; i < itemSize; i++){
				Map<String, Object> item = (Map<String, Object>) items[i];
				rows.add(parseRow(item));
			}
		} else if(deserializedResponse.containsKey('hits')) {
			// cloudsearch search
			Map<String, Object> hits = (Map<String, Object>) deserializedResponse.get('hits');
			if(Integer.valueOf(hits.get('found')) > 0) {
				List<Object> items = (List<Object>) hits.get('hit');
				Integer itemSize = items.size();
				for(Integer i = 0; i < itemSize; i++){
					Map<String, Object> item = (Map<String, Object>) items[i];
					rows.add(parseRowForCS((Map<String, Object>) item.get('fields')));
				}
			}
		} else if(deserializedResponse.containsKey('Item')) {
			// dynamoDB getItem
			Map<String, Object> item = (Map<String, Object>) deserializedResponse.get('Item');
			rows.add(parseRow(item));
		}

		return rows;
	}

	private Map<String, Object> parseRow(Map<String, Object> item) {
		Map<String, Object> row = new Map<String, Object>();
		String caseId;
		String no;
		String title;
		String detail;

		for (String key:item.keySet()) {
			if (key == 'case_id') {
				caseId = (String) ((Map<String, Object>) item.get(key)).get('S');
			} else if (key=='no'){
				no = (String) ((Map<String, Object>) item.get(key)).get('S');
			} else if (key=='title'){
				title = (String) ((Map<String, Object>) item.get(key)).get('S');
			} else if (key=='detail'){
				detail = (String) ((Map<String, Object>) item.get(key)).get('S');
			}
		}

		row.put('case_id', caseId);
		row.put('no', no);
		row.put('title', title);
		row.put('detail', detail);
		row.put('ExternalId', caseId + '-' + no);
		row.put('DisplayUrl', '/x/Cases__x/' + row.get('ExternalId'));

		return row;
	}

	private Map<String, Object> parseRowForCS(Map<String, Object> item) {
		Map<String, Object> row = new Map<String, Object>();
		row.put('case_id', String.valueOf(item.get('case_id')));
		row.put('no', String.valueOf(item.get('no')));
		row.put('title', String.valueOf(item.get('title')));
		row.put('detail', String.valueOf(item.get('detail')));
		row.put('ExternalId', String.valueOf(item.get('case_id')) + '-' + String.valueOf(item.get('no')));
		row.put('DisplayUrl', '/x/Cases__x/' + row.get('ExternalId'));

		return row;
	}

	public class DynamoDBException extends Exception {}
}