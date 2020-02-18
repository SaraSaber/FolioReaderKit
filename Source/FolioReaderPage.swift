//
//  FolioReaderPage.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 10/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import SafariServices
import MenuItemKit
import JSQWebViewController

/// Protocol which is used from `FolioReaderPage`s.
@objc public protocol FolioReaderPageDelegate: class {

    /**
     Notify that the page will be loaded. Note: The webview content itself is already loaded at this moment. But some java script operations like the adding of class based on click listeners will happen right after this method. If you want to perform custom java script before this happens this method is the right choice. If you want to modify the html content (and not run java script) you have to use `htmlContentForPage()` from the `FolioReaderCenterDelegate`.

     - parameter page: The loaded page
     */
    @objc optional func pageWillLoad(_ page: FolioReaderPage)

    /**
     Notifies that page did load. A page load doesn't mean that this page is displayed right away, use `pageDidAppear` to get informed about the appearance of a page.

     - parameter page: The loaded page
     */
    @objc optional func pageDidLoad(_ page: FolioReaderPage)
    
    /**
     Notifies that page receive tap gesture.
     
     - parameter recognizer: The tap recognizer
     */
    @objc optional func pageTap(_ recognizer: UITapGestureRecognizer)
}

open class FolioReaderPage: UICollectionViewCell, UIWebViewDelegate, UIGestureRecognizerDelegate {
    weak var delegate: FolioReaderPageDelegate?
    weak var readerContainer: FolioReaderContainer?

    /// The index of the current page. Note: The index start at 1!
    open var pageNumber: Int!
    open var webView: FolioReaderWebView?

    fileprivate var colorView: UIView!
    fileprivate var shouldShowBar = true
    fileprivate var menuIsVisible = false

    fileprivate var readerConfig: FolioReaderConfig {
        guard let readerContainer = readerContainer else { return FolioReaderConfig() }
        return readerContainer.readerConfig
    }

    fileprivate var book: FRBook {
        guard let readerContainer = readerContainer else { return FRBook() }
        return readerContainer.book
    }

    fileprivate var folioReader: FolioReader {
        guard let readerContainer = readerContainer else { return FolioReader() }
        return readerContainer.folioReader
    }

    // MARK: - View life cicle

    public override init(frame: CGRect) {
        // Init explicit attributes with a default value. The `setup` function MUST be called to configure the current object with valid attributes.
        self.readerContainer = FolioReaderContainer(withConfig: FolioReaderConfig(), folioReader: FolioReader(), epubPath: "")
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear

        NotificationCenter.default.addObserver(self, selector: #selector(refreshPageMode), name: NSNotification.Name(rawValue: "needRefreshPageMode"), object: nil)
    }

    public func setup(withReaderContainer readerContainer: FolioReaderContainer) {
        self.readerContainer = readerContainer
        guard let readerContainer = self.readerContainer else { return }

        if webView == nil {
             webView = FolioReaderWebView(frame: webViewFrame(), readerContainer: readerContainer)
            webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView?.dataDetectorTypes = .link
            webView?.scrollView.showsVerticalScrollIndicator = false
            webView?.scrollView.showsHorizontalScrollIndicator = false
            webView?.backgroundColor = .clear
            self.contentView.addSubview(webView!)
        }
        webView?.delegate = self

        if colorView == nil {
            colorView = UIView()
            colorView.backgroundColor = self.readerConfig.nightModeBackground
            webView?.scrollView.addSubview(colorView)
        }

        // Remove all gestures before adding new one
        webView?.gestureRecognizers?.forEach({ gesture in
            webView?.removeGestureRecognizer(gesture)
        })
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.delegate = self
        webView?.addGestureRecognizer(tapGestureRecognizer)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }

    deinit {
        webView?.scrollView.delegate = nil
        webView?.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        webView?.setupScrollDirection()
        webView?.frame = webViewFrame()
    }

    func webViewFrame() -> CGRect {
        guard (self.readerConfig.hideBars == false) else {
            return bounds
        }

        let statusbarHeight = UIApplication.shared.statusBarFrame.size.height
        let navBarHeight = self.folioReader.readerCenter?.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
        let navTotal = self.readerConfig.shouldHideNavigationOnTap ? 0 : statusbarHeight + navBarHeight
        let paddingTop: CGFloat = 20
        let paddingBottom: CGFloat = 30

        return CGRect(
            x: bounds.origin.x,
            y: self.readerConfig.isDirection(bounds.origin.y + navTotal, bounds.origin.y + navTotal + paddingTop, bounds.origin.y + navTotal),
            width: bounds.width,
            height: self.readerConfig.isDirection(bounds.height - navTotal, bounds.height - navTotal - paddingTop - paddingBottom, bounds.height - navTotal)
        )
    }

    func loadHTMLString(_ htmlContent: String!, baseURL: URL!) {
        // Insert the stored highlights to the HTML
        let tempHtmlContent = htmlContentWithInsertHighlights(htmlContent)
        // Load the html into the webview
        print("tempHtmlContent ==== \(tempHtmlContent)")
        webView?.alpha = 0
        var s = """
<?xml version="1.0" encoding="UTF-8"?>

<html class="andada mediaOverlayStyle0 textSizeThree"xml:lang="ar" lang="ar" dir="rtl" xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">

<head>

<meta charset="utf-8" />

<meta name="viewport" content="initial-scale=2.3, user-scalable=no" />

<title> روعة حسابات كيمياء الكم وتطبيقاتها</title>

<link rel="stylesheet" type="text/css" href="../Style/epub.css" />



<script type="text/javascript" src="/var/containers/Bundle/Application/D0E033F8-F006-4364-9418-66862A864D9E/Hindawi Kotob.app/Frameworks/FolioReaderKit.framework/Bridge.js"></script><script type="text/javascript">setMediaOverlayStyleColors("#FF7A4F", "#FFC5B2")</script>
</head><body><div dir="rtl">

<h1 dir="rtl" class="title center">مقدمة</h1>



<p>
            نُعاصر اليومَ طفراتٍ — بشكل يفوق الخيال — في قدرات الحواسيب (سواءٌ المكتبية الصغيرة،
            أو محطات العمل، أو الحواسيب الفائقة) المتاحة في الأسواق، والتي أصبحت أقوى أُسيًّا في
            جميع النواحي، وذلك من حيث عدد المعالجات (النَّوَى) وسرعتها في إجراء العمليات الحسابية،
            سواء بالتوازي أو بالتتابع، وسعة ذاكراتها وسعة تخزين النتائج. نتج عن ذلك قيام الأفراد —
            باحثين كانوا أو طلابًا في الجامعات أو حتى في المدارس الثانوية — باقتناء معدات البحث
            والتعلُّم الخاصة بهم في معاملهم أو حتى في منازلهم.
                </p><p>
            في عام ١٩٧٤ قمتُ مع عدد من طلابي في الدراسات العليا بتنفيذِ برنامجٍ صغيرٍ لحسابات
            التركيب الإلكتروني لجزيئات عضوية بسيطة مثل الأنيلين والبريدين وغيرهما، وكان الحاسوب
            المتاح آنَذاك في مركز الحساب العلمي، الذي أنشأه المرحوم أ.د. فتحي البديوي، أستاذ
            الفيزياء بكلية العلوم في جامعة عين شمس، يُنجز المهمة في حوالي ١٦ دقيقة كاملة، ونحصل على
            النتائج العددية مطبوعةً لنقوم بتحليلها واستخلاص خصائص بسيطة لهذه الجزيئات، وكانتْ
            عملياتٍ معقَّدةً جدًّا إذا ما قُورِنتْ بالمتاح حاليًّا. فاليومَ وباستخدام المتوفر — سواء
            من الحواسيب الصماء أو البرامج — نحصل على النتائج قبل أن يرتدَّ إلينا طرف، بل أصبح في
            الإمكان أيضًا بسهولةٍ ويسرٍ إجراءُ حسابات معقَّدة لمركَّبات كيميائية وبيولوجية كبيرة
            جدًّا باستخدام حُزَمِ برمجياتٍ هائلة متاحة مجانًا للأكاديميين، أو ما يمكن شراءُ رخصةِ
            تشغيله. وليس المراد فقط هو حسابات التركيب الإلكتروني لهذه المركَّبات أو المتراكبات أو
            العديد من المواد، بل أيضًا خواصها الكيميائية والفيزيائية والديناميكية الحرارية وجميع
            أنواع أطيافها، وتفاعُلاتها أيضًا سواءٌ في الحالة الأرضية أو كيمياء الحالة المثارة
            (الكيمياء الضوئية)، وكل هذه المهام تُنجَز في وقتٍ قصير وبتكلفة أقل.
                </p><div dir="rtl" class="section" id="sect1_1"><h4 dir="rtl" class="title">ما أهداف المهام الواجب تنفيذها؟ ولماذا تُنفَّذ؟</h4><div class="paragraph-block">
                تُنفَّذ المهمات الحسابية لثلاثة أسباب واضحة
                (<span dir="ltr">V.I.P.</span>) وهي «ت<b /><sup>٣</sup>»؛ أيْ:
                تحقِّق، وتفسِّر، وتتنبَّأ. وهي باختصار: <b>التحقُّق</b>
                    (<span dir="ltr">Validate</span>) من صحة القياسات المعملية، <b>تفسير</b> (<span dir="ltr">Interpret</span>) النتائج
                المعملية، <b>التنبؤ</b>
                    (<span dir="ltr">Predict</span>) بمركبات وبمتراكبات جديدة ذات خواصَّ
                معينةٍ ومطلوبة .
                    
                    </div><p>
            وسيُشرَح ذلك بعدد من الأمثلة الفعلية في الفصول التالية.
                </p><p>
            ونظرًا لاهتمامنا الشديد بالتعليم، خاصةً التعليم الذاتي، فسنُقدِّم أمثلة عديدة
                مرئية لنتائج حسابية بحُزَم البرامج المتاحة (انظر ملحق (١)) لشرح وتفسير مبادئ أساسية
                في بعض أَفْرُع الكيمياء. وسيجد القارئ عددًا من أمثلةٍ صُمِّمت خصوصًا لتمرين الطلاب،
                ومشروعات حسابية للمختبر باستخدام حُزَمِ بعض البرامج المتاحة؛ ذلك لتعميق المفاهيم
                الصحيحة لأساسيات الكيمياء، ليس فقط على المستوى الثانوي أو التعليم الجامعي، بل أيضًا
                على مستوًى مُتقدِّمٍ يخدم الأبحاث لطلاب الدراسات العليا على مستوى الماجستير
                والدكتوراه، وعلى مستوى الباحثين المؤهَّلين بالدرجات العلمية للترقي في وظائفهم
                البحثية وفي مواقعهم في بعض الصناعات، كالكيمياء الدوائية، والبيئية، ومواد الطاقة،
                والخلايا الشمسية، والأصباغ وغيرها.
                </p><p>
            وسأقدِّم شرحًا مختصرًا، وإنْ كان وافيًا، لأمثلةٍ توضح خطوات العمل، وللطرق
                المستخدَمة في حسابات الخواص المختلفة وحُزَم بعض برامج كيمياء الكم المتاحة، وبرامج
                عرض النتائج الرسومية ومصادرها، بالإضافة إلى نوعية الحواسيب.
                </p><p>
            سأتجنَّب تمامًا الخوْضَ في كل ما يُنفِّر القارئ المبتدئ من هذا المجال الخصب،
                وخاصةً النظريات الرياضية لميكانيكا الكم وطرق حلولها (الخوارزميات)، بل سأُلمِّح إلى
                الطرق الحسابية الأكثر شيوعًا والأسرع والأكثر دقةً للحصول على نتائجَ نظريةٍ تتوافق مع
                النتائج المعملية. وفي يقيني أن هذا النهج سيجذب مزيدًا من الدارسين، ويفتح المجال
                للاستزادة الذاتية للتعمق والتوسع في المعرفة، وكلما اقتضت الحاجة.
                </p><p>
            وتُعَد الكيمياء الحاسوبية رخيصةَ الكُلفة إلى حدٍّ ما، إذا قُورِنت بإجراء التجارب
                المعملية، وهي سريعةٌ مُقارَنةً بالتجرِبة، وهي كذلك آمِنة بيئيًّا. لكنها لا تحلُّ
                محلَّ التجرِبة، التي ما زالت تُمثِّل حقيقةً لطبيعة ما ندرسه معمليًّا. علاوةً على
                ذلك، فإنه لصُنْعِ شيءٍ ما — مثل أدوية جديدة، أو مواد جديدة للطاقة مثلًا — يجب إجراء
                التجارب في المعمل. لكن أصبح اللجوء إلى الحسابات أمرًا بديهيًّا وموثوقًا به لجدوى
                اقتراح المادة المراد تحضيرها، وذلك قبل الشروع في إجراء التجارب معمليًّا.
                </p><p>
            وصدق الرأي القائل إننا في الكيمياء الحاسوبية نُحاكِي سلوكَ الجزيئات الحقيقية
                بمساعدة النماذج التي تعكس بدقةٍ كبيرة سلوكَ الذرات والجزيئات في الواقع.
                </p><p>
            ويُمكِن اعتبار هذه المقدمة دليلًا عمليًّا أوليًّا ومحفِّزًا ليُرشِد ويعطي دَفْعةً
                لكل مهتمٍّ بمعرفةِ هذا المجال الهام، وقد يكون مُلهِمًا لمحبي العلم والتعلُّم كي
                يَستزيدوا ويتعمَّقوا في خوضِ هذه الرقعة الممتدة، ودراسةِ أبعادها وحدودها المترامية،
                والإلمام بدُروبها دونَ دليلٍ سوى كُتَيِّباتِ شرحِ حُزَمِ البرامج المختلفة.
                </p><p>
            لا كمالَ في العلم، وَلْينهلْ كلُّ دارسٍ قدْرَ اهتمامه واحتياجاته، ويتعمَّق بما
                يُطِيق لتحقيقِ ما يصبو إليه، لمُواكَبة ما يجري على الساحة العالمية. ومَن سار على هذا
                الدرب قد يه واحتياجاته، ويتعمَّق بما
                يُطِيق لتحقيقِ ما يصبو إليه، لمُواكَبة ما يجري على الساحة العالمية. ومَن سار على هذا
                الدرب قد ي\331ُضيف ويَبتكِر، لتكون لنا الريادةُ والسَّبْق؛ لهذا تطلَّبَ الأمر تقديم هذا
                المجال باللغة العربية الأم، لسلامة الفهم وتجنُّبًا للعوائق اللغوية، ولتخطي حاجز
                الاستيعاب باللغة الأجنبية. وأنا على يقينٍ أن هذا العمل سيُساهم في تحقيق المأمول من
                انتشار هذا الفرع من العلوم المعاصرة، وتثبيت مفاهيم التعلم والفهم للابتكار في مجالات
                تعليمية وأبحاث علمية وتطبيقية ذات مردود اقتصادي ووَقْع إيجفرع من العلوم المعاصرة، وتثبيت مفاهيم التعلم والفهم للابتكار في مجالات
                تعليمية وأبحاث علمية وتطبيقية ذات مردود اقتصادي ووَقْع إيج\330ابي على المجتمع.
                </p><p>
            وعلى الله قصد السبيل.
                </p><div class="para_flushleft align_left"><div>المؤلف     <br />أ.د. محمد صبري أحمد عبد المطلب</div></div></div>

</div><div><br></div></body></html>
"""
        webView?.loadHTMLString(s, baseURL: baseURL)
    }

    // MARK: - Highlights

    fileprivate func htmlContentWithInsertHighlights(_ htmlContent: String) -> String {
        var tempHtmlContent = htmlContent as NSString
        // Restore highlights
        guard let bookId = (self.book.name as NSString?)?.deletingPathExtension else {
            return tempHtmlContent as String
        }

        let highlights = Highlight.allByBookId(withConfiguration: self.readerConfig, bookId: bookId, andPage: pageNumber as NSNumber?)

        if (highlights.count > 0) {
            for item in highlights {
                let style = HighlightStyle.classForStyle(item.type)
                
                var tag = ""
                if let _ = item.noteForHighlight {
                    tag = "<highlight id=\"\(item.highlightId!)\" onclick=\"callHighlightWithNoteURL(this);\" class=\"\(style)\">\(item.content!)</highlight>"
                } else {
                    tag = "<highlight id=\"\(item.highlightId!)\" onclick=\"callHighlightURL(this);\" class=\"\(style)\">\(item.content!)</highlight>"
                }
                
                var locator = item.contentPre + item.content
                locator += item.contentPost
                locator = Highlight.removeSentenceSpam(locator) /// Fix for Highlights
                
                let range: NSRange = tempHtmlContent.range(of: locator, options: .literal)
                
                if range.location != NSNotFound {
                    let newRange = NSRange(location: range.location + item.contentPre.count, length: item.content.count)
                    tempHtmlContent = tempHtmlContent.replacingCharacters(in: newRange, with: tag) as NSString
                } else {
                    print("highlight range not found")
                }
            }
        }
        return tempHtmlContent as String
    }

    // MARK: - UIWebView Delegate

    open func webViewDidFinishLoad(_ webView: UIWebView) {
        guard let webView = webView as? FolioReaderWebView else {
            return
        }

        delegate?.pageWillLoad?(self)

        // Add the custom class based onClick listener
        self.setupClassBasedOnClickListeners()

        refreshPageMode()

        if self.readerConfig.enableTTS && !self.book.hasAudio {
            webView.js("wrappingSentencesWithinPTags()")

            if let audioPlayer = self.folioReader.readerAudioPlayer, (audioPlayer.isPlaying() == true) {
                audioPlayer.readCurrentSentence()
            }
        }

        let direction: ScrollDirection = self.folioReader.needsRTLChange ? .positive(withConfiguration: self.readerConfig) : .negative(withConfiguration: self.readerConfig)

        if (self.folioReader.readerCenter?.pageScrollDirection == direction &&
            self.folioReader.readerCenter?.isScrolling == true &&
            self.readerConfig.scrollDirection != .horizontalWithVerticalContent) {
            scrollPageToBottom()
        }

        UIView.animate(withDuration: 0.2, animations: {webView.alpha = 1}, completion: { finished in
            webView.isColors = false
            self.webView?.createMenu(options: false)
        })

        delegate?.pageDidLoad?(self)
    }

    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard
            let webView = webView as? FolioReaderWebView,
            let scheme = request.url?.scheme else {
                return true
        }

        guard let url = request.url else { return false }

        if scheme == "highlight" || scheme == "highlight-with-note" {
            shouldShowBar = false

            guard let decoded = url.absoluteString.removingPercentEncoding else { return false }
            let index = decoded.index(decoded.startIndex, offsetBy: 12)
            let rect = CGRectFromString(String(decoded[index...]))

            webView.createMenu(options: true)
            webView.setMenuVisible(true, andRect: rect)
            menuIsVisible = true

            return false
        } else if scheme == "play-audio" {
            guard let decoded = url.absoluteString.removingPercentEncoding else { return false }
            let index = decoded.index(decoded.startIndex, offsetBy: 13)
            let playID = String(decoded[index...])
            let chapter = self.folioReader.readerCenter?.getCurrentChapter()
            let href = chapter?.href ?? ""
            self.folioReader.readerAudioPlayer?.playAudio(href, fragmentID: playID)

            return false
        } else if scheme == "file" {

            let anchorFromURL = url.fragment

            // Handle internal url
            if !url.pathExtension.isEmpty {
                let pathComponent = (self.book.opfResource.href as NSString?)?.deletingLastPathComponent
                guard let base = ((pathComponent == nil || pathComponent?.isEmpty == true) ? self.book.name : pathComponent) else {
                    return true
                }

                let path = url.path
                let splitedPath = path.components(separatedBy: base)

                // Return to avoid crash
                if (splitedPath.count <= 1 || splitedPath[1].isEmpty) {
                    return true
                }

                let href = splitedPath[1].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                let hrefPage = (self.folioReader.readerCenter?.findPageByHref(href) ?? 0) + 1

                if (hrefPage == pageNumber) {
                    // Handle internal #anchor
                    if anchorFromURL != nil {
                        handleAnchor(anchorFromURL!, avoidBeginningAnchors: false, animated: true)
                        return false
                    }
                } else {
                    self.folioReader.readerCenter?.changePageWith(href: href, animated: true)
                }
                return false
            }

            // Handle internal #anchor
            if anchorFromURL != nil {
                handleAnchor(anchorFromURL!, avoidBeginningAnchors: false, animated: true)
                return false
            }

            return true
        } else if scheme == "mailto" {
            print("Email")
            return true
        } else if url.absoluteString != "about:blank" && scheme.contains("http") && navigationType == .linkClicked {

            if #available(iOS 9.0, *) {
                let safariVC = SFSafariViewController(url: request.url!)
                safariVC.view.tintColor = self.readerConfig.tintColor
                safariVC.modalPresentationStyle = .fullScreen
                self.folioReader.readerCenter?.present(safariVC, animated: true, completion: nil)
            } else {
                let webViewController = WebViewController(url: request.url!)
                let nav = UINavigationController(rootViewController: webViewController)
                nav.view.tintColor = self.readerConfig.tintColor
                nav.modalPresentationStyle = .fullScreen
                self.folioReader.readerCenter?.present(nav, animated: true, completion: nil)
            }
            return false
        } else {
            // Check if the url is a custom class based onClick listerner
            var isClassBasedOnClickListenerScheme = false
            for listener in self.readerConfig.classBasedOnClickListeners {

                if scheme == listener.schemeName,
                    let absoluteURLString = request.url?.absoluteString,
                    let range = absoluteURLString.range(of: "/clientX=") {
                    let baseURL = String(absoluteURLString[..<range.lowerBound])
                    let positionString = String(absoluteURLString[range.lowerBound...])
                    if let point = getEventTouchPoint(fromPositionParameterString: positionString) {
                        let attributeContentString = (baseURL.replacingOccurrences(of: "\(scheme)://", with: "").removingPercentEncoding)
                        // Call the on click action block
                        listener.onClickAction(attributeContentString, point)
                        // Mark the scheme as class based click listener scheme
                        isClassBasedOnClickListenerScheme = true
                    }
                }
            }

            if isClassBasedOnClickListenerScheme == false {
                // Try to open the url with the system if it wasn't a custom class based click listener
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                    return false
                }
            } else {
                return false
            }
        }

        return true
    }

    fileprivate func getEventTouchPoint(fromPositionParameterString positionParameterString: String) -> CGPoint? {
        // Remove the parameter names: "/clientX=188&clientY=292" -> "188&292"
        var positionParameterString = positionParameterString.replacingOccurrences(of: "/clientX=", with: "")
        positionParameterString = positionParameterString.replacingOccurrences(of: "clientY=", with: "")
        // Separate both position values into an array: "188&292" -> [188],[292]
        let positionStringValues = positionParameterString.components(separatedBy: "&")
        // Multiply the raw positions with the screen scale and return them as CGPoint
        if
            positionStringValues.count == 2,
            let xPos = Int(positionStringValues[0]),
            let yPos = Int(positionStringValues[1]) {
            return CGPoint(x: xPos, y: yPos)
        }
        return nil
    }

    // MARK: Gesture recognizer

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view is FolioReaderWebView {
            if otherGestureRecognizer is UILongPressGestureRecognizer {
                if UIMenuController.shared.isMenuVisible {
                    webView?.setMenuVisible(false)
                }
                return false
            }
            return true
        }
        return false
    }

    @objc open func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        self.delegate?.pageTap?(recognizer)
        
        if let _navigationController = self.folioReader.readerCenter?.navigationController, (_navigationController.isNavigationBarHidden == true) {
            let selected = webView?.js("getSelectedText()")
            
            guard (selected == nil || selected?.isEmpty == true) else {
                return
            }

            let delay = 0.4 * Double(NSEC_PER_SEC) // 0.4 seconds * nanoseconds per seconds
            let dispatchTime = (DispatchTime.now() + (Double(Int64(delay)) / Double(NSEC_PER_SEC)))
            
            DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                if (self.shouldShowBar == true && self.menuIsVisible == false) {
                    self.folioReader.readerCenter?.toggleBars()
                }
            })
        } else if (self.readerConfig.shouldHideNavigationOnTap == true) {
            self.folioReader.readerCenter?.hideBars()
            self.menuIsVisible = false
        }
    }

    // MARK: - Public scroll postion setter

    /**
     Scrolls the page to a given offset

     - parameter offset:   The offset to scroll
     - parameter animated: Enable or not scrolling animation
     */
    open func scrollPageToOffset(_ offset: CGFloat, animated: Bool) {
        let pageOffsetPoint = self.readerConfig.isDirection(CGPoint(x: 0, y: offset), CGPoint(x: offset, y: 0), CGPoint(x: 0, y: offset))
        webView?.scrollView.setContentOffset(pageOffsetPoint, animated: animated)
    }

    /**
     Scrolls the page to bottom
     */
    open func scrollPageToBottom() {
        guard let webView = webView else { return }
        let bottomOffset = self.readerConfig.isDirection(
            CGPoint(x: 0, y: webView.scrollView.contentSize.height - webView.scrollView.bounds.height),
            CGPoint(x: webView.scrollView.contentSize.width - webView.scrollView.bounds.width, y: 0),
            CGPoint(x: webView.scrollView.contentSize.width - webView.scrollView.bounds.width, y: 0)
        )

        if bottomOffset.forDirection(withConfiguration: self.readerConfig) >= 0 {
            DispatchQueue.main.async {
                self.webView?.scrollView.setContentOffset(bottomOffset, animated: false)
            }
        }
    }

    /**
     Handdle #anchors in html, get the offset and scroll to it

     - parameter anchor:                The #anchor
     - parameter avoidBeginningAnchors: Sometimes the anchor is on the beggining of the text, there is not need to scroll
     - parameter animated:              Enable or not scrolling animation
     */
    open func handleAnchor(_ anchor: String,  avoidBeginningAnchors: Bool, animated: Bool) {
        if !anchor.isEmpty {
            let offset = getAnchorOffset(anchor)

            switch self.readerConfig.scrollDirection {
            case .vertical, .defaultVertical:
                let isBeginning = (offset < frame.forDirection(withConfiguration: self.readerConfig) * 0.5)

                if !avoidBeginningAnchors {
                    scrollPageToOffset(offset, animated: animated)
                } else if avoidBeginningAnchors && !isBeginning {
                    scrollPageToOffset(offset, animated: animated)
                }
            case .horizontal, .horizontalWithVerticalContent:
                scrollPageToOffset(offset, animated: animated)
            }
        }
    }

    // MARK: Helper

    /**
     Get the #anchor offset in the page

     - parameter anchor: The #anchor id
     - returns: The element offset ready to scroll
     */
    func getAnchorOffset(_ anchor: String) -> CGFloat {
        let horizontal = self.readerConfig.scrollDirection == .horizontal
        if let strOffset = webView?.js("getAnchorOffset('\(anchor)', \(horizontal.description))") {
            return CGFloat((strOffset as NSString).floatValue)
        }

        return CGFloat(0)
    }

    // MARK: Mark ID

    /**
     Audio Mark ID - marks an element with an ID with the given class and scrolls to it

     - parameter identifier: The identifier
     */
    func audioMarkID(_ identifier: String) {
        guard let currentPage = self.folioReader.readerCenter?.currentPage else {
            return
        }

        let playbackActiveClass = self.book.playbackActiveClass
        currentPage.webView?.js("audioMarkID('\(playbackActiveClass)','\(identifier)')")
    }

    // MARK: UIMenu visibility

    #warning("Share feature disable")

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let webView = webView else { return false }

        if UIMenuController.shared.menuItems?.count == 0 {
            webView.isColors = false
            webView.createMenu(options: false)
        }
        #warning("Share feature disable")

        if /*!webView.isShare && */ !webView.isColors {
            if let result = webView.js("getSelectedText()") , result.components(separatedBy: " ").count == 1 {
                webView.isOneWord = true
                webView.createMenu(options: false)
            } else {
                webView.isOneWord = false
            }
        }

        return super.canPerformAction(action, withSender: sender)
    }

    // MARK: ColorView fix for horizontal layout
    @objc func refreshPageMode() {
        guard let webView = webView else { return }

        if (self.folioReader.nightMode == true) {
            // omit create webView and colorView
            let script = "document.documentElement.offsetHeight"
            let contentHeight = webView.stringByEvaluatingJavaScript(from: script)
            let frameHeight = webView.frame.height
            let lastPageHeight = frameHeight * CGFloat(webView.pageCount) - CGFloat(Double(contentHeight!)!)
            colorView.frame = CGRect(x: webView.frame.width * CGFloat(webView.pageCount-1), y: webView.frame.height - lastPageHeight, width: webView.frame.width, height: lastPageHeight)
        } else {
            colorView.frame = CGRect.zero
        }
    }
    
    // MARK: - Class based click listener
    
    fileprivate func setupClassBasedOnClickListeners() {
        for listener in self.readerConfig.classBasedOnClickListeners {
            self.webView?.js("addClassBasedOnClickListener(\"\(listener.schemeName)\", \"\(listener.querySelector)\", \"\(listener.attributeName)\", \"\(listener.selectAll)\")");
        }
    }
    
    // MARK: - Public Java Script injection
    
    /** 
     Runs a JavaScript script and returns it result. The result of running the JavaScript script passed in the script parameter, or nil if the script fails.
     
     - returns: The result of running the JavaScript script passed in the script parameter, or nil if the script fails.
     */
    open func performJavaScript(_ javaScriptCode: String) -> String? {
        return webView?.js(javaScriptCode)
    }
}
