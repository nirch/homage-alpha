--------------------------
Project highest structure:
--------------------------

- Data

    - Model                         : Core data model of the local storage.
    - Networking                    : Requests to the servers and network reachability (Never update UI or read/write local storage from this layer!)
    - Parsers                       : Consumers that translate data objects from server to the Core Data Model.
    - ManagedDocument               : The managed document storing the local storage.
    
- App

    - Fonts                         : Fonts files used in this app. DINOT(DINOT-Regular) and DIN OT(DINOT-CondBold).
    - Notification Center           : Related to *local* notifications used to notify different layers of the app about occured events.
    - Logs                          : Logging macros
    - Supporting Files              : General projects files, headers and plists

- UserInterface

    - Main                          : Main story board view controllers (Stories, remakes lists etc).
    - Recorder                      : Video Cam recorder UI and functionality.
    - Login                         : Login screens.
    - Custom Views & Effects        : Custom controlls and views. Special UI effects. *No logic / VC here. Just views & FX!*.
    - Experimental                  : A playgroud to check UI elements. Don't put anything here that should be a part of the app.




--------------------------
DATA Layer
--------------------------

- Model

    - Model.xcdatamodeld            : Core Data model scheme
    - DB                            : A singleton class holding core data info (context, reference to managed document etc.)
    - Entities                      : Auto generated entity objects. Don't edit these files. (created using core data IDE.)
    - Factories                     : Categories on the entities. Add model logic here.
    
- Networking

    - ServerCFG.plist               : Config file for the HMServer class (Configures the urls, protocol used etc.)
    - HMServer                      : Uses AFNetworking 2.0 to communicate with the server. Singleton, loads ServerCFG.plist on initialization.
    - WebService                    : Categories on HMServer for handling requests to the web service.
    - LazyLoading                   : Categories on HMServer for handling background lazy loading of assets from the server.