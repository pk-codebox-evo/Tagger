/**
 * Copyright (c) 2016 Ivan Magda
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

// MARK: Types

private enum SectionType: Int, CaseCountable {
    
    case Trends
    case Categories
    
    enum TrendingTags: Int, CaseCountable {
        case Today, Week
        
        static let sectionTitle = "Trending Tags"
        static let tags = ["now", "this week"]
    }
    
    enum UserCategories {
        static let sectionTitle = "Categories"
    }
    
}

private enum SegueIdentifier: String {
    case TagCategoryDetail
}

// MARK: - DiscoverTagsViewController: UIViewController, Alertable -

class DiscoverTagsViewController: UIViewController, Alertable {
    
    // MARK: Outlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Properties
    
    private let flickrApiClient = FlickrApiClient.sharedInstance
    
    private var numberOfColumns = 2
    private let defaultTagCategories = [
        "art", "light", "park", "winter", "sun", "clouds", "family", "football", "macro", "summer"
    ]
    
    private var images = [String: UIImage]()
    private var imagesIsInLoading = Set<NSIndexPath>()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        numberOfColumns += (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 1 : -1)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
}

// MARK: - DiscoverTagsViewController (UI Methods)  -

extension DiscoverTagsViewController {
    
    private func configureUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        guard let layout = collectionView!.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        layout.sectionInset = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
        layout.minimumInteritemSpacing = 8.0
        layout.minimumLineSpacing = 8.0
        collectionView.contentInset.top += layout.sectionInset.top
    }
    
}

// MARK: - DiscoverTagsViewController: UICollectionViewDataSource -

extension DiscoverTagsViewController: UICollectionViewDataSource {
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return SectionType.countCases()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = SectionType(rawValue: section) else { return 0 }
        switch section {
        case .Trends:
            return SectionType.TrendingTags.caseCount
        case .Categories:
            return defaultTagCategories.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TagCollectionViewCell.reuseIdentifier, forIndexPath: indexPath) as! TagCollectionViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: SectionHeaderCollectionReusableView.reuseIdentifier, forIndexPath: indexPath) as! SectionHeaderCollectionReusableView
            configureSectionHeaderView(headerView, forIndexPath: indexPath)
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    // MARK: Helpers
    
    private func configureCell(cell: TagCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        func failedToLoadImageWithError(error: NSError) {
            setImage(nil, toCellAtIndexPath: indexPath)
            print("Failed to load an image. Error: \(error.localizedDescription)")
        }
        
        let tag = tagFromIndexPath(indexPath)
        cell.title.text = tag
        updateTitleColorForCell(cell)
        
        if let image = images[tag] {
            cell.imageView.image = image
            updateTitleColorForCell(cell)
            return
        }
        
        guard imagesIsInLoading.contains(indexPath) == false else { return }
        imagesIsInLoading.insert(indexPath)
        
        if indexPath.section == SectionType.Trends.rawValue {
            let period: Period = (indexPath.row == SectionType.TrendingTags.Today.rawValue ? .Day : .Week)
            flickrApiClient.tagsHotListForPeriod(period, successBlock: { [unowned self] tags in
                let tags = tags.map { $0.name }
                self.flickrApiClient.randomImageFromTags(tags, successBlock: { [weak self] image in
                    self?.setImage(image, toCellAtIndexPath: indexPath)
                    }, failBlock: failedToLoadImageWithError)
                }, failBlock: failedToLoadImageWithError)
        } else {
            flickrApiClient.randomImageFromTags([tag], successBlock: { [weak self] image in
                self?.setImage(image, toCellAtIndexPath: indexPath)
                }, failBlock: failedToLoadImageWithError)
        }
    }
    
    private func setImage(image: UIImage?, toCellAtIndexPath indexPath: NSIndexPath) {
        imagesIsInLoading.remove(indexPath)
        
        guard collectionView.indexPathsForVisibleItems().contains(indexPath) == true else { return }
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? TagCollectionViewCell else { return }
        
        cell.imageView.image = image
        images[tagFromIndexPath(indexPath)] = image
        updateTitleColorForCell(cell)
    }
    
    private func updateTitleColorForCell(cell: TagCollectionViewCell) {
        cell.title.textColor = cell.imageView.image != nil ? .whiteColor() : .blackColor()
    }
    
    private func tagFromIndexPath(indexPath: NSIndexPath) -> String {
        return (indexPath.section == SectionType.Trends.rawValue
            ? SectionType.TrendingTags.tags[indexPath.row]
            : defaultTagCategories[indexPath.row]
        )
    }
    
    private func configureSectionHeaderView(view: SectionHeaderCollectionReusableView, forIndexPath indexPath: NSIndexPath) {
        guard let section = SectionType(rawValue: indexPath.section) else { return }
        switch section {
        case .Trends:
            view.title.text = SectionType.TrendingTags.sectionTitle
        case .Categories:
            view.title.text = SectionType.UserCategories.sectionTitle
        }
    }
    
}

// MARK: - DiscoverTagsViewController: UICollectionViewDelegateFlowLayout -

extension DiscoverTagsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSizeZero
        }
        
        let sectionInsets = layout.sectionInset
        let minimumInteritemSpacing = layout.minimumInteritemSpacing
        
        let remainingWidth = collectionView.bounds.width
            - sectionInsets.left
            - CGFloat((numberOfColumns - 1)) * minimumInteritemSpacing
            - sectionInsets.right
        let width = floor(remainingWidth / CGFloat(numberOfColumns))
        
        return CGSize(width: width, height: width)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard collectionView.numberOfItemsInSection(section) > 0 else { return CGSizeZero }
        return CGSize(width: collectionView.bounds.width, height: SectionHeaderCollectionReusableView.height)
    }
    
}

// MARK: - DiscoverTagsViewController: UICollectionViewDelegate -

extension DiscoverTagsViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        
        switch indexPath.section {
        case SectionType.Trends.rawValue:
            let period = indexPath.row == 0 ? Period.Day : Period.Week
            let hotTagsViewController = FlickrHotTagsViewController(period: period, flickrApiClient: flickrApiClient)
            hotTagsViewController.title = SectionType.TrendingTags.tags[indexPath.row].capitalizedString
            navigationController?.pushViewController(hotTagsViewController, animated: true)
        case SectionType.Categories.rawValue:
            let tag = defaultTagCategories[indexPath.row]
            let relatedTagsViewController = FlickrRelatedTagsViewController(flickrApiClient: flickrApiClient, tag: tag)
            navigationController?.pushViewController(relatedTagsViewController, animated: true)
        default:
            break
        }
    }
    
}
