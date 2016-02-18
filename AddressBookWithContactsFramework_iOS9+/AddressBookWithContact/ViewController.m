//
//  ViewController.m
//  AddressBookWithContact
//
//  Created by shared on 2/16/16.
//  Copyright © 2016 shared. All rights reserved.
//

#import "ViewController.h"
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,CNContactViewControllerDelegate,CNContactPickerDelegate,UINavigationControllerDelegate>

{
    BOOL isNewContact;
    __block NSMutableArray *arrContact;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController


//MARK:- view controller cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setTableFooterView:[[UIView alloc]initWithFrame:CGRectZero]];
    arrContact = [[NSMutableArray alloc]init];
    isNewContact = NO;
}



-(void)viewWillAppear:(BOOL)animated
{
    [self getAllContacts];
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



//MARK:- to get all contacts
-(void)getAllContacts
{
    [arrContact removeAllObjects];
    CNContactStore*  store = [[CNContactStore alloc]init];
    CNContactFetchRequest *fetchReq = [[CNContactFetchRequest alloc]initWithKeysToFetch:@[CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataAvailableKey, CNContactImageDataKey, CNContactViewController.descriptorForRequiredKeys]];
    
    fetchReq.sortOrder = CNContactSortOrderUserDefault;//For showing contact same as phonebook sorting
    
    [store enumerateContactsWithFetchRequest:fetchReq error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL  *_Nonnull stop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [arrContact addObject:contact];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        });
        
        
    }];
}
// MARK:- add contact by interface

- (IBAction)addContact:(id)sender {
    CNContact *cont = [[CNContact alloc]init];
    CNContactViewController *contactViewVC = [CNContactViewController  viewControllerForNewContact:cont];
    contactViewVC.delegate = self;
    contactViewVC.allowsEditing = YES;
    contactViewVC.allowsActions = YES;
    self.navigationController.navigationBarHidden = NO;
    contactViewVC.navigationController.navigationBarHidden = NO;
    contactViewVC.navigationController.delegate = self;
    isNewContact = YES;
    [self.navigationController pushViewController:contactViewVC animated:YES];
    
}

//MARK:- datasource & delegate methods of table

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
       return arrContact.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cellForTable";
    UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    CNContact  *person = [arrContact objectAtIndex:indexPath.row];
    
    NSString *firstName = person.givenName;
    NSString *lastName = person.familyName;
    if((firstName == nil && lastName == nil) || (firstName.length == 0 && lastName.length == 0) ){
        cell.textLabel.text = @"No name assigned";
    }
    else{
        if(firstName == nil)
            firstName = @"";
        if(lastName == nil)
            lastName = @"";
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CNContact *contact = [arrContact objectAtIndex:indexPath.row];
    CNContactViewController *contactViewVC = [CNContactViewController viewControllerForContact:contact];
    contactViewVC.delegate = self;
    contactViewVC.allowsEditing = YES;
    contactViewVC.allowsActions = YES;
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.delegate = self;
    [self.navigationController pushViewController:contactViewVC animated:TRUE];
}

//MARK :-Navigation controller delegate method
//THis is bug in iOS9 of Apple
//see the link:-
//https://forums.developer.apple.com/message/82793#82793
//http://stackoverflow.com/questions/32973254/cncontactviewcontroller-forunknowncontact-unusable-destroys-interface
//http://stackoverflow.com/questions/34725890/cncontactviewcontroller-hide-navigationbar-after-contactimagefullscreenview
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if(navigationController.topViewController != self){
        UIView * navView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64)];
        navView.backgroundColor = [UIColor grayColor];
        UIButton *btnBack = [[UIButton alloc] initWithFrame:CGRectMake(-3, 20, 70, 44)];
        [btnBack setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btnBack setTitle:@"Back" forState:UIControlStateNormal];
        [btnBack addTarget:self action:@selector(closePeopleViewPicker) forControlEvents:UIControlEventTouchUpInside];
        [navView addSubview:btnBack];
        [navigationController.topViewController.view addSubview:navView];
        self.navigationController.delegate = nil;
    }
}


-(void)closePeopleViewPicker
{
    [self.navigationController popViewControllerAnimated:YES];
}

//MARK:- CNContactViewController Delegate
- (BOOL)contactViewController:(CNContactViewController *)viewController shouldPerformDefaultActionForContactProperty:(CNContactProperty *)property{
    NSLog(@"Key:%@\nValue:%@",property.key,property.value);
    return YES;
}

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(nullable CNContact *)contact{
    NSLog(@"%@",contact);
    if(contact == nil){
        NSLog(@"Cancel btn Pressed...");
        if(isNewContact){
            [self.navigationController popViewControllerAnimated:YES];
            isNewContact = NO;
        }
    }
    else{
        NSLog(@"Done btn Pressed...");
    }
}


//MARK:- add contact manually via code
-(void)addContact
{
    CNContactStore *str = [CNContactStore new];
    
    CNMutableContact *contact = [[CNMutableContact alloc] init];
    contact.familyName = @"pradeepdddkkkhhh";
    contact.givenName = @"kiol";
    
    CNLabeledValue *homePhone = [CNLabeledValue labeledValueWithLabel:CNLabelHome value:[CNPhoneNumber phoneNumberWithStringValue:@"312-555-1212"]];
    contact.phoneNumbers = @[homePhone];
    
    CNSaveRequest *request = [[CNSaveRequest alloc] init];
    [request addContact:contact toContainerWithIdentifier:nil];
    NSError *saveError;
    if (![str executeSaveRequest:request error:&saveError]) {
        NSLog(@"error = %@", saveError);
    }
}

//MARK:- update exiting contact information in contacts via code

-(void)updateContact
{
    if(arrContact.count){
        CNContact *cont = [arrContact lastObject];
        NSLog(@"name to be update %@\n",cont.familyName);
        
        CNContactStore *str = [CNContactStore new];
        CNMutableContact *conta = [cont mutableCopy];
        CNLabeledValue *home = [CNLabeledValue labeledValueWithLabel:CNLabelHome value:@"home@gmail.com"];
        CNLabeledValue *office = [CNLabeledValue labeledValueWithLabel:CNLabelWork value:@"work@gmail.com"];
        
        conta.emailAddresses = @[home,office];
        
        CNSaveRequest *request = [[CNSaveRequest alloc] init];
        [request updateContact:conta];
        
        if(![str executeSaveRequest:request error:nil])
        {
            NSLog(@"can't be updated");
        }
    }
}


//MARK:- delete Contact via code
-(void)deleteContact
{
    if(arrContact.count){
        CNContact *cont = [arrContact lastObject];
        CNContactStore *str = [CNContactStore new];
        CNMutableContact *contactMutable = [cont mutableCopy];
        CNSaveRequest *request = [[CNSaveRequest alloc] init];
        
        [request deleteContact:contactMutable];
        
        if(![str executeSaveRequest:request error:nil])
        {
            NSLog(@"can't be deleted");
        }
    }
}

@end
