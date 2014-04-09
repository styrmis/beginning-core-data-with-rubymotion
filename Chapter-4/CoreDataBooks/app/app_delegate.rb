class AppDelegate
  include CDQ

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    cdq.setup

    root_view_controller = RootViewController.alloc.initWithNibName(nil, bundle: nil)

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.makeKeyAndVisible
    @window.rootViewController = UINavigationController.alloc.\
                              initWithRootViewController(root_view_controller)

    true
  end
end
