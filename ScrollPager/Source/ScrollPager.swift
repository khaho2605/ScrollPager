//
//  ScrollPager.swift
//  ScrollPager
//
//  Created by Aryan Ghassemi on 2/22/15.
//  Copyright (c) 2015 Aryan Ghassemi. All rights reserved.
//

import UIKit

@objc public protocol ScrollPagerDelegate: NSObjectProtocol {
	func scrollPager(scrollPager: ScrollPager, changedIndex: Int)
}

@IBDesignable public class ScrollPager: UIView, UIScrollViewDelegate{
	
	private var selectedIndex = 0
	private let indicatorView = UIView()
	private var buttons = [UIButton]()
	private var views = [UIView]()
	private var animationInProgress = false
	@IBOutlet public var delegate: ScrollPagerDelegate!
	
	@IBOutlet public var scrollView: UIScrollView? {
		didSet {
			scrollView?.delegate = self
			scrollView?.pagingEnabled = true
			scrollView?.showsHorizontalScrollIndicator = false
		}
	}
	
	@IBInspectable public var textColor: UIColor = UIColor.lightGrayColor() {
		didSet{
			redrawComponents()
		}
	}
	
	@IBInspectable public var selectedTextColor: UIColor = UIColor.darkGrayColor() {
		didSet{
			redrawComponents()
		}
	}
	
	@IBInspectable public var font: UIFont = UIFont.systemFontOfSize(13) {
		didSet{
			redrawComponents()
		}
	}

	@IBInspectable public var selectedFont: UIFont = UIFont.boldSystemFontOfSize(13) {
		didSet{
			redrawComponents()
		}
	}
	
	@IBInspectable public var indicatorColor: UIColor = UIColor.blackColor() {
		didSet{
			indicatorView.backgroundColor = indicatorColor
		}
	}
	
	@IBInspectable public var indicatorSizeMatchesTitle: Bool = false {
		didSet{
			redrawComponents()
		}
	}
	
	@IBInspectable public var indicatorHeight: CGFloat = 2.0 {
		didSet{
			redrawComponents()
		}
	}
	
	@IBInspectable public var borderColor: UIColor? {
		didSet{
			self.layer.borderColor = borderColor?.CGColor
		}
	}
	
	@IBInspectable public var borderWidth: CGFloat = 0 {
		didSet{
			self.layer.borderWidth = borderWidth
		}
	}
	
	// MARK: - Initializarion -
	
	public required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		initialize()
	}
	
	private func initialize() {
		#if TARGET_INTERFACE_BUILDER
			addSegments(["Segment 1", "Segment 2", "Segment 3"])
		#endif
	}
	
	// MARK: - UIView Methods -
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		redrawComponents()
		//moveToIndex(selectedIndex, animated: false, moveScrollView: true)
	}
	
	// MARK: - Public Methods -
	
	public func addSegments(segments: [(title: String, view: UIView)]) {
		
		addButtons(segments.map { $0.title })
		
		for i in 0..<segments.count {
			let view = segments[i].view
			scrollView!.addSubview(view)
			views.append(view)
		}
		
		redrawComponents()
	}
	
	public func addSegments(segments: [String]) {
		addButtons(segments)
		redrawComponents()
	}
	
	public func setSelectedIndex(index: Int, animated: Bool, moveScrollView: Bool) {
		selectedIndex = index
		
		moveToIndex(index, animated: animated, moveScrollView: moveScrollView)
	}
	
	// MARK: - Private -
	
	private func addButtons(buttonTitles: [String]) {
		for button in buttons {
			button.removeFromSuperview()
		}
		
		buttons.removeAll(keepCapacity: true)
		
		for i in 0..<buttonTitles.count {
			let button = UIButton.buttonWithType(.Custom) as UIButton
			button.tag = i
			button.setTitle(buttonTitles[i], forState: .Normal)
			button.addTarget(self, action: "buttonSelected:", forControlEvents: .TouchUpInside)
			buttons.append(button)
			
			addSubview(button)
			addSubview(indicatorView)
		}
	}
	
	private func moveToIndex(index: Int, animated: Bool, moveScrollView: Bool) {
		animationInProgress = true
		
		UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: { [weak self] in
			
			let width = self!.frame.size.width / CGFloat(self!.buttons.count)
			let button = self!.buttons[index]
			
			if self!.indicatorSizeMatchesTitle {
				let string: NSString? = button.titleLabel?.text as NSString?
				let size = string?.sizeWithAttributes([NSFontAttributeName: button.titleLabel!.font])
				let x = width * CGFloat(index) + ((width - size!.width) / CGFloat(2))
				self!.indicatorView.frame = CGRectMake(x, self!.frame.size.height - self!.indicatorHeight, size!.width, self!.indicatorHeight)
			}
			else {
				self!.indicatorView.frame = CGRectMake(width * CGFloat(index), self!.frame.size.height - self!.indicatorHeight, button.frame.size.width, self!.indicatorHeight)
			}
			
			if self!.scrollView != nil && moveScrollView {
				self!.scrollView?.contentOffset = CGPointMake(CGFloat(index) * self!.scrollView!.frame.size.width, 0)
			}
			
			}, completion: { [weak self] finished in
				self!.animationInProgress = false
		})
	}
	
	private func redrawComponents() {
		if buttons.count == 0 {
			return
		}
		
		let width = frame.size.width / CGFloat(buttons.count)
		let height = frame.size.height
		
		for i in 0..<buttons.count {
			let button = buttons[i]
			button.frame = CGRectMake(width * CGFloat(i), 0, width, height)
			button.setTitleColor((i == selectedIndex) ? selectedTextColor : textColor, forState: .Normal)
			button.titleLabel?.font = (i == selectedIndex) ? selectedFont : font
		}
		
		moveToIndex(selectedIndex, animated: false, moveScrollView: false)
		
		if scrollView != nil {
			scrollView!.contentSize = CGSizeMake(scrollView!.frame.size.width * CGFloat(buttons.count), scrollView!.frame.size.height)
			
			for i in 0..<views.count {
				views[i].frame = CGRectMake(scrollView!.frame.size.width * CGFloat(i), 0, scrollView!.frame.size.width, scrollView!.frame.size.height)
			}
		}
	}
	
	func buttonSelected(sender: UIButton) {
		if sender.tag == selectedIndex {
			return
		}
		
		delegate.scrollPager(self, changedIndex: sender.tag)
		
		setSelectedIndex(sender.tag, animated: true, moveScrollView: true)
	}
	
	// MARK: - UIScrollView Delegate -

	public func scrollViewDidScroll(scrollView: UIScrollView) {
		if !animationInProgress {
			var page = scrollView.contentOffset.x / scrollView.frame.size.width

			if page % 1 > 0.5 {
				page = page + CGFloat(1)
			}
			
			if Int(page) != selectedIndex {
				setSelectedIndex(Int(page), animated: true, moveScrollView: false)
				delegate.scrollPager(self, changedIndex: Int(page))
			}
		}
	}
	
}