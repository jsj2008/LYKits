#import "LYServiceKit.h"

#ifdef LY_ENABLE_SDK_AWS
@implementation LYServiceAWS
@synthesize data;
- (id)init
{
	self = [super init];
	if (self != nil)
	{
		data = [[NSMutableDictionary alloc] init];
#if 1
		[data key:@"aws-key" v:@"AKIAIG737NOEC2VVPXQQ"];
		[data key:@"aws-secret" v:@"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"];
		[data key:@"aws-key" v:[[data v:@"aws-key"] _ly_k1]];
		[data key:@"aws-secret" v:[[data v:@"aws-secret"] _ly_k1]];
		//NSLog(@"key %@", [data v:@"aws-key"]);
		//NSLog(@"sec %@", [data v:@"aws-secret"]);
#else
		[data key:@"aws-key" v:@"AKIAIG737NOEC2VVPXQQ"];
		[data key:@"aws-secret" v:@"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"];
		NSLog(@"key %@", [[data v:@"aws-key"] _ly_k1]);
		NSLog(@"sec %@", [[data v:@"aws-secret"] _ly_k1]);
#endif
		sdb	= [[AmazonSimpleDBClient alloc] initWithAccessKey:[data v:@"aws-key"] withSecretKey:[data v:@"aws-secret"]];
		s3	= [[AmazonS3Client alloc] initWithAccessKey:[data v:@"aws-key"] withSecretKey:[data v:@"aws-secret"]];
	}
	return self;
}
- (void)dealloc
{
	[sdb release];
	[data release];
	[super dealloc];
}
@end


@implementation LYServiceAWSSimpleDB

/*
 * 
	LYServiceAWSSimpleDB* sdb = [[LYServiceAWSSimpleDB alloc] init];
	//	[sdb test];
#if 0	
	[sdb select:@"select * from `user` where `name` = 'Leo'" block:^(id obj, NSError* error)
	{
		NSArray* array = (NSArray*)obj;
		NSLog(@"select result: %@", error);
		NSLog(@"select data: %@", array);
	}];
#endif
#if 1
	[sdb put:@"users" name:@"leo@superarts.org"];
	[sdb key:@"name" unique:@"Leo3"];
	[sdb key:@"friends" value:@"tom"];
	[sdb key:@"friends" value:@"jerry"];
	[sdb key:@"friends" value:@"kenny"];
	[sdb key:@"gender" value:@"male"];
	[sdb put_block:^(id obj, NSError* error)
	{
		NSLog(@"put result: %@", error);
	}];
#endif
 *
 */
#if 0
- (id)init
{
	self = [super init];
	if (self != nil)
	{
#if 0
		data = [[NSMutableDictionary alloc] init];
		[data key:@"aws-key" v:@"AKIAIG737NOEC2VVPXQQ"];
		[data key:@"aws-secret" v:@"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"];
#endif
	}
	return self;
}

- (void)dealloc
{
	//[sdb release];
	//[data release];
	[super dealloc];
}
#endif

- (void)put:(NSString*)domain
{
	[self put:domain name:[LYRandom unique_string]];
}

- (void)put:(NSString*)domain name:(NSString*)name
{
	request_put = [[SimpleDBPutAttributesRequest alloc] initWithDomainName:domain
															   andItemName:name
															 andAttributes:nil];
														//	 andAttributes:[NSMutableArray array]];
}

- (void)key:(NSString*)key unique:(NSString*)value
{
	//SimpleDBAttribute* attr = [[SimpleDBAttribute alloc] initWithName:key andValue:value];
	SimpleDBReplaceableAttribute* attr = [[SimpleDBReplaceableAttribute alloc] initWithName:key andValue:value andReplace:YES];
	[request_put addAttribute:attr];
	[attr release];
}

- (void)key:(NSString*)key value:(NSString*)value
{
	SimpleDBReplaceableAttribute* attr = [[SimpleDBReplaceableAttribute alloc] initWithName:key andValue:value andReplace:NO];
	[request_put addAttribute:attr];
	[attr release];
}

- (void)put_block:(LYBlockVoidObjError)callback
{
	request_put.delegate = self;
	[sdb putAttributes:request_put];
	[request_put release];
	callback_obj_error = [callback copy];
}

- (NSException*)put_sync
{
	[LYLoading show];
	SimpleDBPutAttributesResponse* response = [sdb putAttributes:request_put];
	[request_put release];
	return response.exception;
}

- (void)select:(NSString*)query block:(LYBlockVoidObjError)callback
{
	SimpleDBSelectRequest* request_select = [[SimpleDBSelectRequest alloc] initWithSelectExpression:query];
	request_select.delegate = self;
	[sdb select:request_select];
	[request_select release];
	callback_obj_error = [callback copy];
}

- (NSArray*)select_sync:(NSString*)query
{
	[LYLoading show];
	SimpleDBSelectRequest* request_select = [[SimpleDBSelectRequest alloc] initWithSelectExpression:query];
	SimpleDBSelectResponse* response_select = [sdb select:request_select];
	[request_select release];
	[LYLoading hide];
	return [self array_from_select:response_select];
	//return response_select.items;
}

- (void)count:(NSString*)query block:(LYBlockVoidIntError)callback
{
	NSString* s = [NSString stringWithFormat:@"SELECT count(*) FROM %@", query];
	//	NSLog(@"count:\n%@", s);
	SimpleDBSelectRequest  *request_select = [[SimpleDBSelectRequest alloc] initWithSelectExpression:s];
	request_select.delegate = self;
	[sdb select:request_select];
	[request_select release];
	callback_int_error = callback;
}

- (int)count_sync:(NSString*)query
{
	[LYLoading show];
	NSString* s = [NSString stringWithFormat:@"SELECT count(*) FROM %@", query];
	SimpleDBSelectRequest  *request_count = [[SimpleDBSelectRequest alloc] initWithSelectExpression:s];
	SimpleDBSelectResponse* response_count = [sdb select:request_count];
	SimpleDBAttribute* attr = [[[response_count.items i:0] attributes] i:0];
	[request_count release];
	[LYLoading hide];
	return [[attr value] intValue];
}

- (void)request:(AmazonServiceRequest*)request didCompleteWithResponse:(AmazonServiceResponse*)response
{
	if ([response class] == [SimpleDBPutAttributesResponse class])
	{
		//	NSLog(@"put successfully: %@", response);
		callback_obj_error(nil, nil);
		[callback_obj_error release];
	}
	else if ([response class] == [SimpleDBSelectResponse class])
	{
		SimpleDBAttribute* attr = nil;
		SimpleDBSelectResponse* response_select = (SimpleDBSelectResponse*)response;
		if (response_select.items.count > 0)
			attr = [[[response_select.items i:0] attributes] i:0];
		if ((attr != nil) && [[attr name] is:@"Count"])
			callback_int_error([[attr value] intValue], nil);
		else
		{
			NSArray* array = [self array_from_select:response_select];
			//	NSLog(@"xxx %@", callback_obj_error);
			callback_obj_error(array, nil);
			//[callback_obj_error release];
		}
		//	NSLog(@"select: %@", response_select.items);
	}
	else
		NSLog(@"AWS response: %@\nclass: '%@'", response, NSStringFromClass([response class]));
}

- (NSMutableArray*)array_from_select:(SimpleDBSelectResponse*)response
{
	NSMutableArray* array = [NSMutableArray array];
	for (SimpleDBItem* item in response.items)
	{
		NSMutableArray* attributes = [NSMutableArray array];
		NSMutableDictionary* attr_unique = [NSMutableDictionary dictionary];
		for (SimpleDBAttribute* attr in item.attributes)
		{
			[attributes addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				attr.value,
				attr.name,
				nil]];
			[attr_unique key:attr.name v:attr.value];
		}
		[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			attributes,
			@"attributes",
			attr_unique,
			@"attr-dict",
			item.name,
			@"name",
			nil]];
	}
	return array;
}

- (void)request:(AmazonServiceRequest*)request didFailWithError:(NSError*)error
{
	callback_obj_error(nil, error);
}

- (void)test
{
	//	[AmazonLogger verboseLogging];
	NSLog(@"AWS testing started...");
	sdb = [[AmazonSimpleDBClient alloc] initWithAccessKey:[data v:@"aws-key"] withSecretKey:[data v:@"aws-secret"]];
#if 1
	SimpleDBSelectRequest  *request_select  = [[[SimpleDBSelectRequest alloc] initWithSelectExpression:@"select * from `user` where `name` = 'Leo1'"] autorelease];
	request_select.delegate = self;
	SimpleDBSelectResponse *response_select = [sdb select:request_select];
	NSLog(@"select: %@", response_select.items);
#endif
#if 0
	SimpleDBPutAttributesRequest* request_put;
	request_put = [[SimpleDBPutAttributesRequest alloc] initWithDomainName:@"user"
															   andItemName:@"item-001"
															 andAttributes:[NSMutableArray arrayWithObjects:
					   [[[SimpleDBReplaceableAttribute alloc] initWithName:@"name" andValue:@"Leo2" andReplace:NO] autorelease], 
					   [[[SimpleDBReplaceableAttribute alloc] initWithName:@"name" andValue:@"Leo3" andReplace:NO] autorelease], 
					   [[[SimpleDBReplaceableAttribute alloc] initWithName:@"name" andValue:@"Leo4" andReplace:NO] autorelease], 
					   [[[SimpleDBReplaceableAttribute alloc] initWithName:@"mail" andValue:@"no2@name.com" andReplace:YES] autorelease], 
					   nil]];
	request_put.delegate = self;
	[sdb putAttributes:request_put];
	[request_put release];
#endif
	[sdb release];
	NSLog(@"AWS testing done");
}

@end


@implementation LYServiceAWSS3

- (id)init
{
	self = [super init];
	if (self)
	{
		[self.data key:@"s3-folder" v:@""];
	}
	return self;
}

- (NSString*)put_file_sync:(NSString*)filename
{
	[LYLoading show];
	NSString* uid = [[self.data v:@"s3-folder"] stringByAppendingString:[LYRandom unique_string]];
	S3PutObjectRequest* request = [[S3PutObjectRequest alloc] initWithKey:uid inBucket:@"us-general"];
	request.cannedACL = [S3CannedACL publicRead];
	request.filename = filename;
	[s3 putObject:request];
	[request release];
	[LYLoading hide];
	return uid;
}

- (NSString*)put_data_sync:(NSData*)a_data
{
	[LYLoading show];
	NSString* uid = [[self.data v:@"s3-folder"] stringByAppendingString:[LYRandom unique_string]];
	S3PutObjectRequest* request = [[S3PutObjectRequest alloc] initWithKey:uid inBucket:@"us-general"];
	request.cannedACL = [S3CannedACL publicRead];
	request.data = a_data;
	[s3 putObject:request];
	[request release];
	[LYLoading hide];
	return uid;
}

- (NSData*)get_data_sync:(NSString*)key
{
	[LYLoading show];
	S3GetObjectRequest* request = [[S3GetObjectRequest alloc] initWithKey:key withBucket:@"us-general"];
	S3GetObjectResponse* response = [s3 getObject:request];
	[request release];
#if 0
	NSLog(@"got: %@", response);
	NSLog(@"body: %@", response.body);
	NSLog(@"length: %i", response.contentLength);
#endif
	[LYLoading hide];
	return response.body;
}

@end
#endif	//	AWS


@implementation LYDatabase

@synthesize data;

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		data = [[NSMutableDictionary alloc] init];
		//[data key:@"host"		v:@"http://super-db.appspot.com/rest"];
		[data key:@"host"		v:@"https://super-db.appspot.com/rest"];
		[data key:@"blob"		v:@"https://super-db.appspot.com/blob"];
		[data key:@"username"	v:@"test"];
		[data key:@"password"	v:@"passwordtest"];
		[data key:@"app"		v:@"org.superarts.i"];
		[data key:@"category"	v:@"General"];
		[data key:@"scheme"		v:[NSMutableDictionary dictionary]];

		[self set_scheme_user];
		[self set_scheme_post];
	}
	return self;
}

- (void)dealloc
{
	[data release];
	[super dealloc];
}

- (void)name:(NSString*)name select:(NSString*)query block:(LYBlockVoidArrayError)callback
{
	NSString* url;
	url = [NSString stringWithFormat:@"%@/%@?%@username=%@&password=%@",
							 [data v:@"host"], name, query,
							 [data v:@"username"],
							 [data v:@"password"]];
	//	NSLog(@"url: %@", url);
	__block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	[request addRequestHeader:@"Accept" value:@"application/json"];
	//[request setRequestMethod:@"GET"];
	[request setCompletionBlock:^{
		NSArray* contents = [[[request.responseString dictionary_json] v:@"list"] v:name];
		//	NSLog(@"response: %@", request.responseString);
		//	NSLog(@"contents: %@", contents);
		callback(contents, nil);
	}];
	[request setFailedBlock:^{
		//	NSLog(@"error: %@", request.error);
		callback(nil, request.error);
	}];
	[request startAsynchronous];
}

- (void)name:(NSString*)name key:(NSString*)query block:(LYBlockVoidArrayError)callback
{
	NSString* url;
	url = [NSString stringWithFormat:@"%@/%@/%@?username=%@&password=%@",
							 [data v:@"host"], name, query,
							 [data v:@"username"],
							 [data v:@"password"]];
		NSLog(@"query key url: %@", url);
	__block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	[request addRequestHeader:@"Accept" value:@"application/json"];
	//[request setRequestMethod:@"GET"];
	[request setCompletionBlock:^{
		NSArray* contents = [[request.responseString dictionary_json] v:name];
		//	NSLog(@"response: %@", request.responseString);
		//	NSLog(@"contents: %@", contents);
		callback(contents, nil);
	}];
	[request setFailedBlock:^{
		//	NSLog(@"error: %@", request.error);
		callback(nil, request.error);
	}];
	[request startAsynchronous];
}

- (void)name:(NSString*)name insert:(NSArray*)array block:(LYBlockVoidArrayError)callback
{
	NSString*		url;
	NSDictionary*	dict;
	dict = [NSDictionary dictionaryWithObjectsAndKeys:
	   [NSDictionary dictionaryWithObjectsAndKeys:
		   array, name, nil],
	   @"list", nil];
	//url = [NSString stringWithFormat:@"%@/%@", [data v:@"host"], name];
	url = [NSString stringWithFormat:@"%@/%@?username=%@&password=%@",
							 [data v:@"host"], name,
							 [data v:@"username"],
							 [data v:@"password"]];
	__block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
	[request addRequestHeader:@"Content-Type" value:@"application/json"];
	//[request setPostValue:@"application/json" forKey:@"Content-Type"];
	//[request setPostValue:[data v:@"username"] forKey:@"username"];
	//[request setPostValue:[data v:@"password"] forKey:@"password"];
	[request appendPostData:(NSData*)[[CJSONSerializer serializer] serializeDictionary:dict error:nil]];
	[request setRequestMethod:@"POST"];
#if 0
	NSLog(@"url: %@", url);
	NSLog(@"request: %@", request);
	NSLog(@"request: %@", request.requestMethod);
	NSLog(@"request: %@", request.postBody);
	NSString* tmp;
	tmp = [[NSString alloc] initWithData:request.postBody encoding:NSUTF8StringEncoding];
	NSLog(@"json %@", tmp);
#endif
	//[request appendPostData:[@"This is my data" dataUsingEncoding:NSUTF8StringEncoding]];
	[request setCompletionBlock:^{
		//	NSLog(@"headers: %@", request.responseHeaders);
		//	NSLog(@"response: %@", request.responseString);
		NSArray* contents = [request.responseString componentsSeparatedByString:@","];
		//	NSLog(@"contents: %@", contents);
		callback(contents, nil);
	}];
	[request setFailedBlock:^{
		//	NSLog(@"error: %@", request.error);
		callback(nil, request.error);
	}];
	[request startAsynchronous];
}

#pragma mark scheme

- (void)set_scheme_user
{
	if ([[data v:@"scheme"] v:@"user"] == nil)
	{
		[[data v:@"scheme"] key:@"user" v:[NSDictionary dictionaryWithObjectsAndKeys:
			@"db100_model",
			@"database",
			[NSNumber numberWithInt:100],
			@"count",
			[NSArray arrayWithObjects:
				@"email",
				nil],
			@"unique",
			[NSArray arrayWithObjects:
				@"email",
				@"name-display",
				@"pin",
				nil],
			@"s",
			[NSArray arrayWithObjects:
				@"apps",
				@"friends",
				nil],
			@"t",
			nil]];
	}
}

- (void)set_scheme_post
{
	if ([[data v:@"scheme"] v:@"post"] == nil)
	{
		[[data v:@"scheme"] key:@"post" v:[NSDictionary dictionaryWithObjectsAndKeys:
			@"db100_model",
			@"database",
			[NSNumber numberWithInt:100],
			@"count",
			[NSArray arrayWithObjects:
				@"post-id",
				nil],
			@"unique",
			[NSArray arrayWithObjects:
				@"post-id",
				@"parent-id",
				@"author-name",
				@"author-email",
				@"title",
				@"parent-url",
				@"category",
				@"app",
				nil],
			@"s",
			[NSArray arrayWithObjects:
				@"content",
				nil],
			@"t",
			nil]];
	}
}

#pragma mark sdb dbxxx

- (void)sdb:(NSString*)dbname insert:(NSArray*)source block:(LYBlockVoidArrayError)callback
{
	NSDictionary* dict			= [[data v:@"scheme"] v:dbname];
	NSMutableArray* array_dest	= [NSMutableArray array];
	int index;
	NSString* type;

	//	NSLog(@"scheme: %@", dict);
	for (NSDictionary* dict_item in source)
	{
		NSMutableDictionary* dest	= [NSMutableDictionary dictionary];

		[dest key:@"name" v:dbname];
		[dest key:@"username" v:[data v:@"username"]];
		[dest key:@"password" v:@"********"];
#if 0
		int i, count;
		if ([[dict v:@"database"] is:@"db30_model"])
			count = 30;
		if ([[dict v:@"database"] is:@"db100_model"])
			count = 100;
		for (i = 0; i < count; i++)
		{
			[dest key:[NSString stringWithFormat:@"s%i", i] v:@""];
			[dest key:[NSString stringWithFormat:@"t%i", i] v:@""];
		}

		NSString* query_unique = @"";
		for (NSString* item in [dict v:@"unique"])
			query_unique = [query_unique stringByAppendingFormat:@"feq_%@=%@&", item, [dict_item v:item]];
		NSLog(@"query unique: %@", query_unique);
#endif

		for (NSString* key in dict_item)
		{
			id obj = [dict_item v:key];

			if ([obj isKindOfClass:[NSArray class]])
				obj = [NSString stringWithUTF8String:[(NSData*)[[CJSONSerializer serializer] serializeArray:obj error:nil] bytes]];
			//	else if ([obj isKindOfClass:[NSString class]])
			
			if ([[dict v:@"s"] indexOfObject:key] != NSNotFound)
				type = @"s";
			else if ([[dict v:@"t"] indexOfObject:key] != NSNotFound)
				type = @"t";

			index = [[dict v:type] indexOfObject:key];
			//	NSLog(@"%i: %@", index, key);
			[dest key:[NSString stringWithFormat:@"%@%i", type, index] v:obj];
		}
		[array_dest addObject:dest];
	}
	//	NSLog(@"dest: %@", dest);
#if 1
	[self name:[dict v:@"database"] insert:array_dest block:^(NSArray* array, NSError* error)
	{
		callback(array, error);
		//	NSLog(@"add user result: %@ - %@", error, array);
	}];
#endif
}

- (NSDictionary*)dictionary_with_scheme:(NSDictionary*)scheme dict:(NSDictionary*)dict
{
	NSMutableDictionary* ret = [NSMutableDictionary dictionary];
	NSString* s;
	id obj;
	for (int i = 0; i < [[scheme v:@"count"] intValue]; i++)
	{
		s = [NSString stringWithFormat:@"s%i", i];
		if ([dict v:s] != nil)
			[ret key:[[scheme v:@"s"] i:i] v:[dict v:s]];
		s = [NSString stringWithFormat:@"t%i", i];
		if ([dict v:s] != nil)
		{
			obj = [[dict v:s] obj_json];
			if (obj != nil)
				[ret key:[[scheme v:@"t"] i:i] v:[[dict v:s] obj_json]];
			else
				[ret key:[[scheme v:@"t"] i:i] v:[dict v:s]];
		}
	}
	[ret key:@"create" v:[dict v:@"create"]];
	[ret key:@"update" v:[dict v:@"update"]];
	[ret key:@"name" v:[dict v:@"name"]];
	[ret key:@"key" v:[dict v:@"key"]];
	return ret;
}

- (void)sdb:(NSString*)dbname select:(NSDictionary*)dict block:(LYBlockVoidArrayError)callback
{
	NSString* query = @"";
	NSDictionary* scheme = [[data v:@"scheme"] v:dbname];

	for (NSString* key in dict)
	{
		//	NSLog(@"k/v: %@, %@ - %@", key, [dict v:key], [scheme v:@"s"]);
		NSString* s = [NSString stringWithFormat:@"s%i", [[scheme v:@"s"] indexOfObject:key]];
		query = [query stringByAppendingFormat:@"feq_%@=%@&", s, [dict v:key]];
	}
	if (query.length == 0)
	{
		//	NSLog(@"query is empty");
		callback(nil, [NSError errorWithDomain:@"Query is Empty" code:2 userInfo:nil]);
		return;
	}
	NSLog(@"sdb select query: %@", query);

	[self name:[scheme v:@"database"] select:query block:^(NSArray* array, NSError* error)
	{
		NSArray* source;
		NSMutableArray* dest = [NSMutableArray array];
		if ([array isKindOfClass:[NSDictionary class]])
			source = [NSArray arrayWithObjects:array, nil];
		else
			source = array;
		for (NSDictionary* dict in source)
			[dest addObject:[self dictionary_with_scheme:scheme dict:dict]];
		callback(dest, error);
	}];
}

- (void)sdb:(NSString*)dbname verify:(NSDictionary*)dict block:(LYBlockVoidDictError)callback
{
	NSString* query = @"";
	NSDictionary* scheme = [[data v:@"scheme"] v:dbname];

	for (NSString* key in dict)
	{
		//	NSLog(@"k/v: %@, %@ - %@", key, [dict v:key], [scheme v:@"s"]);
		NSString* s = [NSString stringWithFormat:@"s%i", [[scheme v:@"s"] indexOfObject:key]];
		query = [query stringByAppendingFormat:@"feq_%@=%@&", s, [dict v:key]];
	}
	if (query.length == 0)
	{
		//	NSLog(@"query is empty");
		callback(nil, [NSError errorWithDomain:@"Query is Empty" code:2 userInfo:nil]);
		return;
	}

	//	NSLog(@"verify: %@, scheme: %@", query, scheme);
	[self name:[scheme v:@"database"] select:query block:^(NSArray* array, NSError* error)
	{
#if 0
		NSDictionary* dict = (NSDictionary*)array;
		NSMutableDictionary* ret = [NSMutableDictionary dictionary];
		NSString* s;
		id obj;
		//	NSLog(@"%@ - %@", error, dict);
		for (int i = 0; i < [[scheme v:@"count"] intValue]; i++)
		{
			s = [NSString stringWithFormat:@"s%i", i];
			if ([dict v:s] != nil)
				[ret key:[[scheme v:@"s"] i:i] v:[dict v:s]];
			s = [NSString stringWithFormat:@"t%i", i];
			if ([dict v:s] != nil)
			{
				obj = [[dict v:s] obj_json];
				if (obj != nil)
					[ret key:[[scheme v:@"t"] i:i] v:[[dict v:s] obj_json]];
				else
					[ret key:[[scheme v:@"t"] i:i] v:[dict v:s]];
			}
		}
		[ret key:@"create" v:[dict v:@"create"]];
		[ret key:@"update" v:[dict v:@"update"]];
		[ret key:@"name" v:[dict v:@"name"]];
		[ret key:@"key" v:[dict v:@"key"]];
		//	NSLog(@"result: %@", ret);
		callback(ret, error);
#endif
		callback([self dictionary_with_scheme:scheme dict:(NSDictionary*)array], error);
	}];
}

- (void)sdb:(NSString*)dbname key:(NSString*)s block:(LYBlockVoidDictError)callback
{
	[self name:[[[data v:@"scheme"] v:dbname] v:@"database"] key:s block:^(NSArray* array, NSError* error)
	{
		callback((NSDictionary*)array, error);
	}];
}

- (void)sdb:(NSString*)dbname insert_unique:(NSDictionary*)dict block:(LYBlockVoidStringError)callback
{
	NSDictionary* source = dict;
	NSString* error_id = @"ID ";

	NSString* query_unique = @"";
	for (NSString* item in [[[data v:@"scheme"] v:dbname] v:@"unique"])
	{
		NSString* s = [NSString stringWithFormat:@"s%i", [[[[data v:@"scheme"] v:dbname] v:@"s"] indexOfObject:item]];
		query_unique = [query_unique stringByAppendingFormat:@"feq_%@=%@&", s, [dict v:item]];
		error_id = [error_id stringByAppendingFormat:@"%@ ", item];
	}
	error_id = [error_id stringByAppendingFormat:@"Must Be Unique"];
	//	NSLog(@"query unique: %@", query_unique);

	[self name:[[[data v:@"scheme"] v:dbname] v:@"database"] select:query_unique block:^(NSArray* array, NSError* error)
	{
		//	NSLog(@"result: %@ - %@, %i", error, array, array.count);
		if (array.count > 0)
		{
			callback(nil, [NSError errorWithDomain:error_id code:1 userInfo:nil]);
		}
		else
		{
			[self sdb:dbname insert:[NSArray arrayWithObjects:source, nil] block:^(NSArray* array, NSError* error)
			{
				callback([array i:0], error);
			}];
		}
	}];
}

#pragma mark blob

- (NSString*)url_blob:(NSString*)function
{
	return [NSString stringWithFormat:@"%@/%@", [data v:@"blob"], function];
}

- (NSString*)url_blob_serve:(NSString*)key
{
	return [NSString stringWithFormat:@"%@/%@", [self url_blob:@"serve"], key];
}

- (NSString*)blob_upload:(NSData*)data_upload type:(NSString*)type
{
	return [[self url_blob:@"add"] blob_post_dictionary:[NSDictionary dictionaryWithObjectsAndKeys:
		[data v:@"username"],
		@"username",
		[data v:@"password"],
		@"password",
		[NSDictionary dictionaryWithObjectsAndKeys:
			data_upload,
			@"data",
			[NSString stringWithFormat:@"ly-service-blob-%@", [LYRandom unique_string]],
			@"filename",
			type,
			@"type",
			nil],
		@"file",
		nil]];
}

- (NSString*)blob_upload_jpeg:(UIImage*)image
{
	return [self blob_upload:UIImageJPEGRepresentation(image, 80) type:@"image/jpeg"];
}

#pragma mark user extension

- (void)insert_user:(NSDictionary*)dict block:(LYBlockVoidArrayError)callback
{
	NSDictionary* source = dict;

	NSString* query_unique = @"";
	for (NSString* item in [[[data v:@"scheme"] v:@"user"] v:@"unique"])
	{
		NSString* s = [NSString stringWithFormat:@"s%i", [[[[data v:@"scheme"] v:@"user"] v:@"s"] indexOfObject:item]];
		query_unique = [query_unique stringByAppendingFormat:@"feq_%@=%@&", s, [dict v:item]];
	}
	//	NSLog(@"query unique: %@", query_unique);

	[self name:[[[data v:@"scheme"] v:@"user"] v:@"database"] select:query_unique block:^(NSArray* array, NSError* error)
	{
		if ([array count] > 0)
		{
			//	NSLog(@"user already exists");
			callback(nil, [NSError errorWithDomain:@"E-mail Already Exists" code:1 userInfo:nil]);
		}
		else
		{
			//	NSLog(@"result: %@ - %@, %i", error, array, array.count);
			[self sdb:@"user" insert:[NSArray arrayWithObjects:source, nil] block:^(NSArray* array, NSError* error)
			{
				callback(array, error);
			}];
		}
	}];
}

#pragma mark test

- (void)test
{
	LYDatabase* db = [[LYDatabase alloc] init];

	//	select
#if 0
	//[db name:@"database_model" select:@"" block:^(NSArray* array, NSError* error)
	//[db name:@"database_model" select:@"feq_desc=desc-002&" block:^(NSArray* array, NSError* error)
	[db name:@"database_model" key:@"agpzfnN1cGVyLWRichULEg5kYXRhYmFzZV9tb2RlbBjrBww" block:^(NSArray* array, NSError* error)
	{
		NSLog(@"result: %@ - %@", error, array);
	}];
	//	[db db100_model:@"user" select:@"" block:nil];
#endif

	//	insert
#if 0
	[db name:@"database_model" insert:[NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:@"id-006", @"id", @"desc-006", @"desc", @"data-006", @"data", nil],
		nil] block:^(NSArray* array, NSError* error)
	{
		NSLog(@"result: %@ - %@", error, array);
	}];
#endif

	//	insert array
#if 0
	//	insert into dbxxx (with scheme already given)
	[db set_scheme_user];
	[db sdb:@"user" insert:[NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"no1@name.com",
			@"email",
			@"Leo.004",
			@"name-display",
			[NSMutableArray arrayWithObjects:
				@"noa@name.com",
				@"nob@name.com",
				nil],
			@"friends",
			nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"no2@name.com",
			@"email",
			@"Leo.005",
			@"name-display",
			[NSMutableArray arrayWithObjects:
				@"noa@name.com",
				@"nob@name.com",
				nil],
			@"friends",
			nil],
		nil] block:^(NSArray* array, NSError* error)
	{
		//	NSLog(@"result sdb insert: %@ - %@", error, array);
	}];
#endif

	//	insert user
#if 0
	[db insert_user:[NSDictionary dictionaryWithObjectsAndKeys:
		@"no5@name.com",
		@"email",
		@"Leo.004",
		@"name-display",
		[NSMutableArray arrayWithObjects:
			@"noa@name.com",
		@"nob@name.com",
		nil],
		@"friends",
		nil] block:^(NSArray* array, NSError* error)
	{
		NSLog(@"result user insert: %@ - %@", error, array);
	}];
#endif

	//	insert dictionary
#if 0
	[db sdb:@"user" insert_unique:[NSDictionary dictionaryWithObjectsAndKeys:
		@"no5@name.com",
		@"email",
		@"Leo.004",
		@"name-display",
		[NSMutableArray arrayWithObjects:
			@"noa@name.com",
		@"nob@name.com",
		nil],
		@"friends",
		nil] block:^(NSString* str, NSError* error)
	{
		NSLog(@"result user insert: %@ - %@", error, str);
	}];
#endif
	[db release];
}

@end


@implementation LYServiceFaceDotCom

@synthesize data;

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		data = [[NSMutableDictionary alloc] init];
		[data key:@"host"	v:@"http://api.face.com"];
		[data key:@"key"	v:@"a354202bc6a9000b86f3da747470a64b"];
		[data key:@"secret"	v:@"cf03cb8a4dc6696259ff9664f49e6b4d"];
	}
	return self;
}

- (void)dealloc
{
	[data release];
	[super dealloc];
}

- (void)limits:(LYBlockVoidDictError)callback
{
	NSString* url = [NSString stringWithFormat:@"%@/account/limits?api_key=%@&api_secret=%@",
									   [data v:@"host"],
									   [data v:@"key"],
									   [data v:@"secret"]];
	//	NSLog(@"url: %@", url);
	__block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	[request addRequestHeader:@"Accept" value:@"application/json"];
	[request setCompletionBlock:^{
		NSDictionary* dict = [request.responseString dictionary_json];
		if ([[dict v:@"status"] is:@"success"])
			callback([dict v:@"usage"], nil);
		else
			callback(nil, [NSError errorWithDomain:@"FACE Get Limit Failed" code:1 userInfo:nil]);
	}];
	[request setFailedBlock:^{
		//	NSLog(@"error: %@", request.error);
		callback(nil, request.error);
	}];
	[request startAsynchronous];
}

- (void)detect:(NSString*)filename block:(LYBlockVoidArrayError)callback
{
	NSString* url = [NSString stringWithFormat:@"%@/faces/detect?api_key=%@&api_secret=%@&detector=Aggressive&attributes=all",
									   [data v:@"host"],
									   [data v:@"key"],
									   [data v:@"secret"]];
	__block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
	[request addRequestHeader:@"Accept" value:@"application/json"];
	[request setRequestMethod:@"POST"];
	[request setFile:filename forKey:@"_file"];
	NSLog(@"FACE url: %@", url);
	[request setCompletionBlock:^{
		NSDictionary* dict = [request.responseString dictionary_json];
		NSLog(@"response: %@", dict);
		if ([[dict v:@"status"] is:@"success"])
			callback([dict v:@"photos"], nil);
		else
			callback(nil, [NSError errorWithDomain:@"FACE Get Limit Failed" code:1 userInfo:nil]);
	}];
	[request setFailedBlock:^{
		callback(nil, request.error);
	}];
	[request startAsynchronous];
}

@end


@implementation LYServiceLyricWiki

@synthesize data;

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		data = [[NSMutableDictionary alloc] init];
		[data key:@"host"	v:@"http://lyrics.wikia.com"];
		[data key:@"head"	v:@"<div class='lyricbox'>"];
		[data key:@"tail"	v:@"<p>NewPP limit report"];
	}
	return self;
}

- (void)dealloc
{
	[data release];
	[super dealloc];
}

- (void)lyric_by_artist:(NSString*)artist song:(NSString*)song block:(LYBlockVoidStringError)callback
{
	NSString* url = [NSString stringWithFormat:@"%@/%@:%@", [data v:@"host"], [artist to_url], [song to_url]];
	__block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
	//	NSLog(@"LYRIC url: %@", url);
	[request setCompletionBlock:^{
		NSString* html = request.responseString;
		NSRange range_head, range_tail;
		range_head = [html rangeOfString:[data v:@"head"]];
		range_tail = [html rangeOfString:[data v:@"tail"]];
		if (range_head.location != NSNotFound)
		{
			html = [html substringFromIndex:range_head.location + range_head.length];
			html = [html substringToIndex:range_tail.location - range_head.location - range_head.length];

			range_head = [html rangeOfString:@"</div>"];
			if (range_head.location != NSNotFound)
			{
				html = [html substringFromIndex:range_head.location + range_head.length];
				html = [html substringToIndex:html.length - 6];
				callback(html, nil);
			}
			else
				callback(nil, [NSError errorWithDomain:@"Error Parsing Lyric" code:3 userInfo:nil]);
			//	NSLog(@"LYRIC html: %@", html);
		}
		else
			callback(nil, [NSError errorWithDomain:@"Lyric Not Found" code:4 userInfo:nil]);
	}];
	[request setFailedBlock:^{
		callback(nil, request.error);
	}];
	[request startAsynchronous];
}

@end
