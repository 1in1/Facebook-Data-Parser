# Facebook Data Parser


Provides a set of Ruby scripts, and a full CLI menu interface, for parsing the (typically enormous) messages.htm file included in Facebooks downloadable data pack. Currently includes tools to list the message threads available, print threads or write them to file, and resolve the jibberish FB IDs given in some files in place of a name.

***

If  you download your Facebook data, it is provided as a supposedly browsable set of pages. However, the messages.htm page is typically so large it will crash or hang any and every browser that attempts to open it. These tools hopefully give an alternate way to extract the data, with some nicer formatting (and eventually archiving?) thrown in. 

To get ahold of the data itself to work with, visit www.facebook.com while signed in, and visit settings. Open the "Your Facebook information" tab, and click to view "Download your information". From here, you can generate a downloadable file containing various information that FB holds on you. Ensuring messages is selected, set the file for preparation, and wait (possibly for quite a while...). Once done, you can point this script at html/messages.htm

***

Built with one external library, for the GET requests - the rest-client gem: https://github.com/rest-client/rest-client
