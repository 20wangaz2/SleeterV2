Installation Instructions:
BEFORE STARTING, A COMPUTER WITH MAC OS TAHO 26.0.1 OR ABOVE IS REQUIRED

1) Either open the GitHub link in the report and download the project file or open the Sleeter file submitted on canvas. 
2) Install Xcode 26 by going to https://developer.apple.com/news/releases/ and scrolling down till you see an Xcode version of 26 or higher (it can be any version over 26 but Xcode 26.1.1 beta is recommended)
3) After opening Xcode, navigate to the top left of the screen and click on the Xcode tab top left. 
4) Click settings
5) on the left scroll section, scroll to components and install iOS 26 or above simulator (installing other simulators additionally is ok)
6) Go back to the Sleeter file and double click to open, then you should see this file, and a folder called AppSleeter
7) double click the AppSleeter folder
8)Double click the AppSleeter.xcodeproj
9) on the Xcode, click the play button on the top left (dependencies should be automatically downloaded), if dependencies are not automatically downloaded, go to top left File -> add package dependencies... and https://github.com/firebase/firebase-ios-sdk paste this link into the top right url search area and target AppSleeter for everything. Do the same steps for the second dependencies github.com/google/GoogleSignIn-iOS .

10)open the simulator and have fun!

File structure overview:
The AppSleeper folder has the project file, and other files necessary to run the simulator. The main executable file is the AppSleeter.xcodeproj
The other folders are UI tests and tests of the app. 

Attributions:
Everyone worked on every part, but the main ones for each person are:
Andrew - HomeView, WaterView, research for water and log in/log out with firebase
Kolby - SleepView and research on sleep. integration with the stats for HomeView. 
Matthew - WorkoutView, research, models of the workouts and scheduling
