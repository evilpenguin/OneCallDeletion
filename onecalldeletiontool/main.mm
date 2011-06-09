#import <sqlite3.h>
#import <UIKit/UIKit.h>

static inline bool sqlite_was_successful(int result) {
	switch (result) {
		case SQLITE_OK:
		case SQLITE_DONE:
			return YES;
		default:
			return NO;
	}
}

static void deleteCallAtIndex(NSString *index) {
	sqlite3 *database = NULL;
	NSString *path = @"/var/wireless/Library/CallHistory/call_history.db";
	int result = sqlite3_open_v2([path UTF8String], &database, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, nil);
	if (sqlite_was_successful(result)) {
		sqlite3_stmt *statement = NULL;
		result = sqlite3_prepare_v2(database, "Select * from call", -1, &statement, NULL);
		
		NSString *deleteQuery = [NSString stringWithFormat:@"DELETE FROM call WHERE ROWID = %@", index];
		NSLog(@"%@", deleteQuery);
		
		char *errorMsg;
		result = sqlite3_exec(database, [deleteQuery UTF8String], NULL, NULL, &errorMsg);
		sqlite3_finalize(statement);
		if (sqlite_was_successful(result)) {
			NSLog(@"OneCallDeletionTool Deleted Call %@", index);
		}
		else { 
			NSLog(@"OneCallDeletionTool Error: %s", errorMsg);
			sqlite3_free(errorMsg);
		}
        sqlite3_close(database);
	}
	else { NSLog(@"OneCallDeletionTool Error: %@", sqlite3_errmsg(database)); }
}

int main(int argc, char **argv, char **envp) {
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	if (!argv[1]) {
		[p drain];
		return 0;
	}
	NSString *parameter = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
	deleteCallAtIndex(parameter);
	[p drain];
	return 0;
}
