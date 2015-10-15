public without sharing class V4 {
	public static final String HASH_ALGORITHM = 'SHA-256';
	public static final String MAC_ALGORITHM = 'hmacSHA256';
	public static final String SIGNATURE_VERSION = 'AWS4';
	public static final String SIGNATURE_ALGORITHM = 'AWS4-HMAC-SHA256';

	public static String signature(AWSAccessSettings aas, String param){

		// Task 1: Create a Canonical Request For Signature Version 4
		String cs = aas.method + '\n';
		cs += aas.canonicalUri + '\n';
		if(aas.method.toLowerCase().equals('get')) {
			cs += param;
		}
		cs += '\n';
		cs += 'host:' + aas.host + '\n';
		if(aas.signedHeaders.indexOf('x-amz-date') >= 0) {
			cs += 'x-amz-date:' + aas.now + '\n';
		}
		if(aas.signedHeaders.indexOf('x-amz-target') >= 0) {
			cs += 'x-amz-target:' + aas.xAmzTarget + '\n';
		}
		cs += '\n';
		cs += aas.signedHeaders + '\n';
		if(aas.method.toLowerCase().equals('post')) {
			cs += EncodingUtil.convertToHex(Crypto.generateDigest(HASH_ALGORITHM, Blob.valueOf(param)));
		}
		if(aas.method.toLowerCase().equals('get')) {
			cs += EncodingUtil.convertToHex(Crypto.generateDigest(HASH_ALGORITHM, Blob.valueOf('')));
		}

		system.debug('cs:' + cs);

		// Task 2: Create a String to Sign for Signature Version 4
		String sts = SIGNATURE_ALGORITHM + '\n';
		sts += aas.now + '\n';
		sts += aas.today + '/' + aas.region + '/' + aas.serviceName.toLowerCase() + '/aws4_request\n';

		// Task 3: Calculate the AWS Signature Version 4
		Blob keyDate = Crypto.generateMac(MAC_ALGORITHM, Blob.valueOf(aas.today), Blob.valueof(SIGNATURE_VERSION + aas.secretAccessKey));
		Blob keyRegion = Crypto.generateMac(MAC_ALGORITHM, Blob.valueOf(aas.region), keyDate);
		Blob keyService = Crypto.generateMac(MAC_ALGORITHM, Blob.valueOf(aas.serviceName.toLowerCase()), keyRegion);
		Blob keyCredentials = Crypto.generateMac(MAC_ALGORITHM, Blob.valueOf('aws4_request'), keyService);

		// Task 1 + Task 2
		sts += EncodingUtil.convertToHex(Crypto.generateDigest(HASH_ALGORITHM, Blob.valueOf(cs)));

		// Task 2 + Task 3
		return EncodingUtil.convertToHex(Crypto.generateMac(MAC_ALGORITHM, Blob.valueOf(sts), keyCredentials));
	}
}