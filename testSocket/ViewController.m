//
//  ViewController.m
//  testSocket
//
//  Created by Le Tuan Son on 8/15/13.
//  Copyright (c) 2013 Le Tuan Son. All rights reserved.
//

#import "ViewController.h"
#import <CFNetwork/CFNetwork.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <arpa/inet.h>
#include <sys/types.h>
#include <netdb.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *broadcastPortTextfield;
@property (weak, nonatomic) IBOutlet UITextView *broadcastMessageTextView;
- (IBAction)broadcast:(id)sender;
- (IBAction)send:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *singleIpPortTextfield;
@property (weak, nonatomic) IBOutlet UITextField *IPAdressTextField;
@property (weak, nonatomic) IBOutlet UITextView *singleIpMessageTextView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)send:(NSString*)msg ip:(NSString*)ip port:(int)port
{
    int sockfd, portno, n;
    struct sockaddr_in serv_addr;
//    struct hostent *server;
    
    char *buffer;

    portno = port;
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0)
        assert("ERROR opening socket");
//    server = gethostbyname(argv[1]);
//    if (server == NULL) {
//        fprintf(stderr,"ERROR, no such host\n");
//        exit(0);
//    }

    memset((char *) &serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = inet_addr([ip UTF8String]);

    serv_addr.sin_port = htons(portno);
    if (connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0)
    {
        NSLog(@"ERROR connecting");
        return @"ERROR connecting";
    }
    buffer = (char*)[msg UTF8String];
    n = write(sockfd,buffer,strlen(buffer));
    if (n < 0)
    {
        NSLog(@"ERROR writing to socket");
        return @"ERROR writing to socket";
    }
    bzero(buffer,256);
    n = read(sockfd,buffer,255);
    if (n < 0)
    {
        NSLog(@"ERROR reading from socket");
        return @"ERROR reading from socket";
    }

    close(sockfd);
    return [NSString stringWithUTF8String:buffer];
}

-(bool) send:(NSString*) msg ipAddress:(NSString*) ip port:(int) p
{
    int sock;
    struct sockaddr_in destination;
    unsigned int echolen;
    int broadcast = 1;
    // if that doesn't work, try this
    //char broadcast = '1';
    
    if (msg == nil || ip == nil)
    {
        printf("Message and/or ip address is null\n");
        return false;
    }
    
    /* Create the UDP socket */
    if ((sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0)
    {
        printf("Failed to create socket\n");      return false;
    }
    
    /* Construct the server sockaddr_in structure */
    memset(&destination, 0, sizeof(destination));
    
    /* Clear struct */
    destination.sin_family = AF_INET;
    
    /* Internet/IP */
    destination.sin_addr.s_addr = inet_addr([ip UTF8String]);
    
    /* IP address */
    destination.sin_port = htons(p);
    
    /* server port */
    setsockopt(sock,
               IPPROTO_IP,
               IP_MULTICAST_IF,
               &destination,
               sizeof(destination));
    char *cmsg = (char*)[msg UTF8String];
    echolen = strlen(cmsg);
    
    // this call is what allows broadcast packets to be sent:
    if (setsockopt(sock,
                   SOL_SOCKET,
                   SO_BROADCAST,
                   &broadcast,
                   sizeof broadcast) == -1)
    {
        perror("setsockopt (SO_BROADCAST)");
        exit(1);
    }
    if (sendto(sock,
               cmsg,
               echolen,
               0,
               (struct sockaddr *) &destination,
               sizeof(destination)) != echolen)
    {
        printf("Mismatch in number of sent bytes\n");
        return false;
    }
    else
    {
        NSLog(@"%@",msg);
        return true;
    }
}


- (IBAction)broadcast:(id)sender {
    if([self send:_broadcastMessageTextView.text ipAddress:@"255.255.255.255" port:_broadcastPortTextfield.text.intValue])
    {
        _broadcastMessageTextView.text = @"SUCCESS";
    }
    else
    {
         _broadcastMessageTextView.text = @"Fail";
    }
}

- (IBAction)send:(id)sender {
    _singleIpMessageTextView.text = [self send:_singleIpMessageTextView.text ip:_IPAdressTextField.text port:_singleIpPortTextfield.text.intValue];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}
@end
