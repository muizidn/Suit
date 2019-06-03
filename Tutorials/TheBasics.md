# The Basics of Suit Development

Suit is a framework for cross-platform application development.  As of today, Suit is still in its early stages of its development, but is moving forward at a rapid pace, and it becoming more polished, stable, and feature-rich by the day.  New contributors are very welcome, so please get in touch if you'd like to become involved in the project.

#How do I...

##...create an application?

```swift
  let rootComponent = CompositeComponent()
  let mainWindow = Window(rootComponent: rootComponent,
                          frame: CGRect(x: 0,
                          		        y: 0,
                                    width: 800,
                                   height: 600),
                  hasTitleBar: true))

  let app = Application.create(with: window)
  app.iconPath = Bundle.main.path(forAsset: "AppIcon", ofType: "png")
  app.launch()
```

##..add content to a window?

As you've seen above, windows have a root component.  A component is where you add your content.  In the above example, you change `CompositeComponent()` to your custom subclass.

```swift

class MyComponent: CompositeComponent {

  func viewDidLoad() {
    super.viewDidLoad()
    
    // custom code here.
  }
}

```

CompositeComponent is almost always the Component to subclass since it allows the composition of multiple different components into a single parent component.

Components are the high-level building blocks of an application.  Going one level deeper, we have `View`.  View is responsible for the actual rendering.  For many applications, you will not need to use views directly; you will instead use component composition to create the screens that make up your application.

  