public virtual without sharing class DynamoDBClient  extends AWSClient{

	public DynamoDBClient(){
		this.setDefaultSettings();
		this.aas.serviceName = 'DynamoDB';
		this.aas.apiVersion = '20120810';
		this.aas.method = 'POST';
		this.aas.contentType = 'application/x-amz-json-1.0';
		this.aas.endpoint = 'https://dynamodb.' + this.aas.region + '.amazonaws.com/';
		this.aas.host = this.aas.serviceName.toLowerCase() + '.' + this.aas.region + '.amazonaws.com';
		this.aas.signedHeaders = 'host;x-amz-date;x-amz-target';
		this.aas.canonicalUri = '/';
	}

	public DynamoDBClient(AWSAccessSettings aas){
		this.aas = aas;
	}

	public AWSAccessResult putItem(String param){
		this.aas.xAmzTarget = this.aas.serviceName + '_' + this.aas.apiVersion + '.' + 'PutItem';
		return this.send(this.createHttpRequest(param));
	}

	public void batchGetItem(){}
	public void batchWriteItem(){}
	public void createTable(){}
	public void deleteItem(){}
	public void deleteTable(){}
	public void describeTable(){}

	public AWSAccessResult getItem(String param){
		this.aas.xAmzTarget = this.aas.serviceName + '_' + this.aas.apiVersion + '.' + 'GetItem';
		return this.send(this.createHttpRequest(param));
	}

	public void listTables(){}
	public void query(){}

	public AWSAccessResult scan(String param){
		this.aas.xAmzTarget = this.aas.serviceName + '_' + this.aas.apiVersion + '.' + 'Scan';
		return this.send(this.createHttpRequest(param));
	}

	public void updateItem(){}
	public void updateTable(){}
}