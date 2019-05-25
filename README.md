![alt text](./suit_banner.png "Suit: Swift cross platform UI framework")

# What is Suit?
Suit is a pure Swift GUI toolkit.  It's been designed from the start to be cross-platform, and supports both macOS and Linux, today, with further platforms planned for the future, including mobile OSes.

# Why?
While in most cases it's preferable to write an app using a given platform's native toolkit, there are some cases where that's not the best choice for financial reasons, or there may be insufficient time to build a quality product on multiple platforms given the required feature set and the expected pace of development.

# Tell me more
Suit uses native font rendering on all its platforms, which provides a native-feel, especially for text-heavy applications.  The aim of Suit is to render all UI components in a way that's consistent with native components on a given platform.  In addition, some platforms will require platform-specific components, such as a ribbon component on Windows, for example.  Suit is a young project and much more work is required in this area.

For layout, Suit uses [Yoga](https://yogalayout.com) to provide a well-tested, fast, and powerful layout engine.  If you're familiar with flexbox layouts in CSS then you'll already be a pro at laying out views in Suit.

# Who is using Suit today?
Suit has primarily been developed hand-in-hand with Stride, a cross-platform IDE for Swift.  That said, while it came to life in order to make Stride a reality, it has never been developed with only Stride in mind, and as it matures the expectation is that more projects will start to use Suit.

# What is the state of Suit today?
It's been in development for more than a year at this point, and so there has been a lot of progress in major areas.  It's still its infancy, however, and is undergoing heavy development.  As such, the API is not stable and users of Suit may find they need to make frequent changes to match changes in the Suit API.  On the other hand, Suit is very usable for many cases today, and for a peek at its progress the best thing to do is check out Stride.  Everything you see is using Suit.

# How can I monitor Suit's progress

You can follow me on [Twitter](https://twitter.com/saniceadonut), where I post frequent progress updates for both Suit and Stride.

# Can I help?

Yes!  You most certainly can!  Please get in touch: pmacro at icloud dot com.

# How do I write a Suit app

The easiest way is to download Stride, create a new project, and select the "Suit App" template.