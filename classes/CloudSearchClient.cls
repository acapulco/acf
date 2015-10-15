public virtual without sharing class CloudSearchClient	extends AWSClient{

	public CloudSearchClient(){
		this.setDefaultSettings();
		this.aas.serviceName = 'cloudsearch';
		this.aas.apiVersion = '2013-01-01';
		this.aas.method = 'GET';
		this.aas.contentType = 'application/x-www-form-urlencoded';
		this.aas.host = this.aas.serviceName.toLowerCase() + '.' + this.aas.region + '.amazonaws.com';
		this.aas.signedHeaders = 'host;x-amz-date';
	}

	public CloudSearchClient(AWSAccessSettings aas){
		this.aas = aas;
	}

	public AWSAccessResult search(String param, String host){
		this.aas.canonicalUri = '/' + this.aas.apiVersion + '/search';
		this.aas.host = host + '.' + this.aas.region + '.cloudsearch.amazonaws.com';
		this.aas.endpoint = 'https://' + this.aas.host + this.aas.canonicalUri;
		return this.send(this.createHttpRequest(param));
	}
}