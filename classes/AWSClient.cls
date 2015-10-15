public without sharing abstract class AWSClient {

	protected AWSAccessSettings aas {get; set;}
	private static Integer calloutMilliSeconds = 0;
	private static Integer timeLeft = 120000;

	protected void setDefaultSettings(){
		this.aas = new AWSAccessSettings();
		this.aas.accessKeyId = AWS__c.getOrgDefaults().AccessKeyId__c;
		this.aas.region = AWS__c.getOrgDefaults().Region__c;
		this.aas.secretAccessKey = AWS__c.getOrgDefaults().SecretAccessKey__c;
	}

	protected virtual HTTPRequest createHttpRequest(String param){

		// setting date and time
		Datetime dt = Datetime.now();
		this.aas.today = dt.formatGmt('yyyyMMdd');
		this.aas.now = this.aas.today + 'T' + dt.formatGmt('HHmmss') + 'Z';

		this.aas.log();

		// Credential
		String credential = this.aas.accessKeyId + '/' + this.aas.today + '/' + this.aas.region + '/' + this.aas.serviceName.toLowerCase() + '/aws4_request';

		HttpRequest req = new HttpRequest();

		// sign
		String sign = V4.signature(this.aas, param);

		req.setHeader('Authorization',V4.SIGNATURE_ALGORITHM + ' Credential=' + credential + ',SignedHeaders=' + this.aas.signedHeaders + ',Signature=' + sign);
		req.setHeader('host', this.aas.host);
		req.setHeader('x-amz-date', this.aas.now);
		if(!String.isEmpty(this.aas.xAmzTarget)) {
			req.setHeader('x-amz-target', this.aas.xAmzTarget);
		}
		req.setHeader('content-type', this.aas.contentType);
		req.setMethod(this.aas.method);

		// for POST
		if(this.aas.method.toLowerCase().equals('post')) {
			req.setEndpoint(this.aas.endpoint);
			req.setBody(param);
		} else if(this.aas.method.toLowerCase().equals('get')) {
			req.setEndpoint(this.aas.endpoint + '?' + param);
		}

		return req;
	}

	protected virtual  AWSAccessResult send(HTTPRequest req){

		AWSAccessResult aar = new AWSAccessResult();

		// Check governor limit
		this.checkLimit();

		// 1 second margin
		req.setTimeout(timeLeft - 1000);

		// send request
		Http http = new Http();
		Long start = Datetime.now().getTime();
		aar.res = http.send(req);
		calloutMilliSeconds += Integer.valueOf(Datetime.now().getTime() - start);
		timeLeft -= calloutMilliSeconds;

		return aar;
	}

	protected virtual void checkLimit(){
		System.debug(LoggingLevel.DEBUG, '---- callout count:' + Limits.getCallouts());

		if(Limits.getLimitCallouts() == Limits.getCallouts()){
			throw new AWSException('Reached the maximum number of HTTP callout');
		}
	}
}