/*
 * Title: OneCallDeletion 
 * Des: Removes a call at a time from Recents view in MobilePhone.app
 * Created by EvilPenguin|
 * irc.evilpengu.in
 * http://evilpenguin.us
 *
 * Enjoy :)
 */

#import <UIKit/UIKit.h>
#import <sqlite3.h>

#define DATABASE_PATH "/private/var/wireless/Library/CallHistory/call_history.db"

@interface RecentsViewController <UITableViewDelegate, UITableViewDataSource>
	- (void) reloadCallData;		
	- (void)_updateNavBarButtons;
	@property(assign) int tableFilterMode;
@end

static bool sqlite_was_successful(int result) {
	switch (result) {
		case SQLITE_OK:
		case SQLITE_DONE:
			return YES;
		default:
			return NO;
	}
}

%hook RecentsViewController
// Hooked Methods
- (void)loadView {
	NSLog(@"OneCallDeletion has taken the penguin!");
	%orig;
}

- (void) _updateNavBarButtons {
	%orig;
	UITableView *table = MSHookIvar<UITableView *>(self, "_table");
	int number = [table numberOfRowsInSection:0];
	if (number <= 0) { ((UIViewController *)self).navigationItem.leftBarButtonItem = nil; }
	else {
		UIBarButtonItem *edit = [[[UIBarButtonItem alloc] initWithTitle:@"Edit"
																  style:UIBarButtonItemStyleBordered
																 target:self
																 action:@selector(edit:)] autorelease];
		((UIViewController *)self).navigationItem.leftBarButtonItem = edit;
		if (table.editing) {
			[((UIViewController *)self).navigationItem.leftBarButtonItem setStyle:UIBarButtonItemStyleDone];
			((UIViewController *)self).navigationItem.leftBarButtonItem.title = @"Done";
		}
	}
}

- (void)_filterWasToggled:(id)toggled {
	%orig;
	[self _updateNavBarButtons];
}

// Added UIBarButtonItem (Edit) Method
%new(v@:)
- (void) edit:(UIBarButtonItem *)sender {
	UITableView *table = MSHookIvar<UITableView *>(self, "_table");
	if (table.editing) {
		[sender setStyle:UIBarButtonItemStyleBordered];
		[table setEditing:NO animated:YES];
		((UIViewController *)self).navigationItem.leftBarButtonItem.title = @"Edit";
	}
	else {
		[sender setStyle:UIBarButtonItemStyleDone];
		[table setEditing:YES animated:YES];
		((UIViewController *)self).navigationItem.leftBarButtonItem.title = @"Done";
	}
}

// Added UITableView Deletion Methods
%new(v@:@)
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

%new(v@:@)
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

%new(v@:@:@)
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		sqlite3 *database = NULL;
		int result = sqlite3_open_v2(DATABASE_PATH, &database, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, nil);
		if (sqlite_was_successful(result)) {
			NSMutableArray *locations = [[NSMutableArray alloc] init];
			sqlite3_stmt *statement = NULL;
			result = sqlite3_prepare_v2(database, "SELECT * FROM call ORDER BY ROWID DESC", -1, &statement, NULL);
			if (sqlite_was_successful(result)) {				
				int callRow = 0;
				while(sqlite3_step(statement) == SQLITE_ROW) {
					callRow = sqlite3_column_int(statement, 0);
					[locations addObject:[NSString stringWithFormat:@"%d", callRow]];
				}
				
				NSString *caller = nil;
				if (self.tableFilterMode == 0) { caller = [locations objectAtIndex:indexPath.row]; }
				else { 
					NSArray *indexPathsForMissedCallsArray = MSHookIvar<NSArray *>(self, "indexPathsForMissedCallsArray");
					NSIndexPath *path  = [indexPathsForMissedCallsArray objectAtIndex:indexPath.row];
					caller = [locations objectAtIndex:path.row];
				}
				
				
				NSString *deleteQuery = [NSString stringWithFormat:@"/usr/bin/onecalldeletiontool %@", caller];
				system([deleteQuery UTF8String]);
				[self reloadCallData];
				[self _updateNavBarButtons];
			}
			[locations removeAllObjects];
			[locations release];
		}
		else { NSLog(@"error: %@", sqlite3_errmsg(database)); }
	}
}

%end