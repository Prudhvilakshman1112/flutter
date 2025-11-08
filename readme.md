📘 README.md — Algorithm Visualizer Lite (Responsive Flutter App)
🎯 Project Title

Algorithm Visualizer Lite — Interactive & Responsive Flutter App

🧠 Overview

Algorithm Visualizer Lite is an interactive Flutter application that allows users to visualize how different algorithms work step by step.
It includes Sorting Algorithms (Bubble, Selection, Insertion) and Binary Search, with visual animations, speed control, code highlighting, and responsive design for all screen sizes.

The app is designed as a single-file Flutter program, integrating every concept learned throughout your Flutter Lab Experiments — from basic UI building to animations, gestures, custom painting, and state management.

🧩 Features

✅ Algorithm Visualization:

Watch Bubble Sort, Selection Sort, Insertion Sort, and Binary Search visualized dynamically.

Each step (comparison, swap, range update) is animated clearly.

✅ Pseudo-code Panel:

Displays the algorithm's pseudo-code side-by-side.

The current step is highlighted live for clarity.

✅ Interactive Controls:

Play, Pause, Step Forward/Backward to navigate through actions.

Speed Slider to control animation speed.

Reset, Generate Steps, Export Steps to replay or review the algorithm’s trace.

✅ Binary Search Target Input:

Users can set a target manually, auto-pick, or randomize it to visualize search operations.

✅ Custom Array Editor:

Modify array values via tap or drag gestures.

Add or remove array elements dynamically.

✅ Responsive Design:

Automatically adapts to wide screens (split panels), tablets (medium layout), and mobiles (bottom sheets).

✅ Beautiful Animated Background:

Soft animated gradients and color transitions built with CustomPainter.

✅ Export Actions:

Export a full textual log of all algorithmic actions performed.

🧪 Flutter Lab Concepts Implemented
Lab Topic / Exercise	Concept Learned	Implementation in This App
Exp 1: Flutter Basics	Scaffold, AppBar, Material Widgets	Used Scaffold, AppBar, Card, FilledButton, OutlinedButton throughout the UI
Exp 2: State Management	Stateful Widgets, setState()	Managed state updates with ChangeNotifier + InheritedWidget (VisualizerState class)
Exp 3: Navigation & Routing	Passing Data between Widgets	Algorithm and target data passed and updated dynamically without routes using inherited context
Exp 4: Forms & Validation	TextFields, Dialog Inputs	Used in “Set Target” dialog and array value editor with validation
Exp 5: GestureDetector	Touch Events	Used vertical drag gestures to change bar heights and tap gestures to edit values
Exp 6: AnimationController / Tween	Animation and Timing	Animated bar swaps, transitions, and background glow
Exp 7: CustomPainter	Drawing Shapes on Canvas	_BarsPainterResponsive paints bars, highlights, and comparisons dynamically
Exp 8: Asynchronous Programming	Future, Timer, async/await	Animation sequencing and playback logic (Timer.periodic and delayed swaps)
Exp 9: Responsive Design	LayoutBuilder, MediaQuery	Adaptive UI for narrow (mobile), medium (tablet), and wide (desktop) layouts
Exp 10: Data Visualization Project	Combining All Concepts	The full app integrates all learned concepts into a cohesive visualization platform
⚙️ Technical Architecture

Main Components:

VisualizerState (ChangeNotifier):

Manages algorithm data, actions, and animation control.

Handles play/pause, reset, generation, and export logic.

CustomPainter (_BarsPainterResponsive):

Dynamically draws colorful bars representing array values.

Highlights comparisons, swaps, and binary search range.

Pseudo-code Panel (_PseudoCode):

Displays algorithm steps and highlights current executing line.

Responsive Layout:

LayoutBuilder + MediaQuery used to adapt layout for various screen widths.

Dialogs & Sheets:

AlertDialog for value editing & binary target setting.

BottomSheet for settings on smaller screens.

🎨 UI Highlights

Smooth animations for bar swaps and range highlighting

Gradient background with glowing particles (CustomPainter)

Material 3 buttons and components for a clean modern look

Responsive layout — adapts to phones, tablets, and laptops automatically

Compact control bar with speed slider and playback icons

🧮 Algorithms Implemented
Algorithm	Visualization Actions	Description
Bubble Sort	Compare, Swap, Mark Sorted	Demonstrates element swapping step-by-step
Selection Sort	Compare, Swap, Mark Fixed	Shows how minimum elements are chosen
Insertion Sort	Compare, Assign, Insert	Displays element shifting for insertion
Binary Search	Range Update, Compare, Highlight	Shows how search range narrows and target found
🧰 Technologies Used

Language: Dart

Framework: Flutter (Material 3)

Architecture: InheritedWidget + ChangeNotifier

UI Concepts: CustomPainter, GestureDetector, AnimationController, LayoutBuilder

Async Features: Future/await, Timer

🚀 How to Run
▶️ Run on DartPad (Online)

Visit https://dartpad.dev/flutter

Copy & paste the full main.dart code (single file)

Click Run ▶️

Interact with the visualizer (change algorithm, play, step, etc.)

🧑‍💻 Run Locally

Install Flutter SDK

Create a new project:

flutter create algo_visualizer
cd algo_visualizer/lib


Replace the default main.dart with this file.

Run using:

flutter run

📊 Example Use

Select Bubble Sort

Click Generate Steps

Press Play to watch swaps animate

Adjust Speed to visualize faster or slower

Switch to Binary Search, click Set Target, and watch how the target is found (or not)

Tap Export Steps to see a detailed log of all actions

🏁 Outcome

This project is a culmination of all 10 Flutter lab experiments, showcasing a real-world interactive visual application that:

Improves algorithm learning through visual engagement

Demonstrates solid Flutter fundamentals and UI design

Represents an innovative, rare, and practical mini-project suitable for college submissions or hackathon demonstrations

💡 Future Enhancements

Add Merge Sort, Quick Sort, and Linear Search

Integrate sound effects for comparisons/swaps

Add 3D-like bar animation using Transform

Export animation as a short video/gif

👨‍💻 Author

Developed by: [Your Name]
Course: B.Tech (3rd Year) — Flutter Lab Project
Institution: [Your College Name]
Instructor: [Optional, if submitting for evaluation]