import UIKit

class VideoViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var liveQuery: CBLLiveQuery!
    var videos: [Video] = []
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if (object as CBLLiveQuery) == liveQuery {
            for (index, row) in enumerate(liveQuery.rows.allObjects) {
                if index >= videos.count {
                    videos.insert(Video(forDocument: (row as CBLQueryRow).document), atIndex: 0)
                }
            }
            
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Video.queryVideos()
        liveQuery = kDatabase.viewNamed("videos").createQuery().asLiveQuery()
        liveQuery.addObserver(self, forKeyPath: "rows", options: .allZeros, context: nil)
    }
    
    deinit {
        liveQuery.removeObserver(self, forKeyPath: "rows")
    }

    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if let indexPath = tableView.indexPathForSelectedRow() {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }

    // MARK: - Table view data source

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("VideoCell", forIndexPath: indexPath) as VideoTableCell

        cell.title.text = videos[indexPath.row].title
        cell.video_id = videos[indexPath.row].video_id
        cell.downloadButton.tag = indexPath.row
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let video = videos[indexPath.row]
            if video.deleteDocument(nil) {
                videos.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        }
    }
    
    @IBAction func startDownload(sender: UIButton) {
        println(sender.tag)
        
        let aVideo = videos[sender.tag]
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(aVideo.video_id, completionHandler: { (video, error) -> Void in
            let mp4Url = (video as XCDYouTubeVideo).streamURLs[18] as NSURL
            let url = NSURL(string: "\(mp4Url.absoluteString!)&\(aVideo.video_id)")!
            self.createDownloadTask(url)
        })
    }
    
    func createDownloadTask(url: NSURL) {
        let task = VideoDownloader.shared().session.downloadTaskWithURL(url)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateProgress:", name: "DownloadProgress", object: task)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishDownload:", name: "DownloadCompletion", object: task)
        
        task.resume()
    }
    
    func updateProgress(notification: NSNotification) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            println(notification.userInfo!["progress"])
        }
    }
    
    func finishDownload(notification: NSNotification) {
        println(notification.userInfo!["filePath"])
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "VideosToEditor" {
            let vc = segue.destinationViewController as EditorViewController
            let video = videos[tableView.indexPathForSelectedRow()!.row]
            vc.video = video
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
