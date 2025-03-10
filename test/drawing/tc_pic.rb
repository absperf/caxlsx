require 'tc_helper.rb'

class TestPic < Test::Unit::TestCase
  def setup
    stub_request(:get, 'https://example.com/sample-image.png')
      .to_return(body: File.new('examples/sample.png'), status: 200)

    @p = Axlsx::Package.new
    ws = @p.workbook.add_worksheet
    @test_img = @test_img_jpg = File.dirname(__FILE__) + "/../fixtures/image1.jpeg"
    @test_img_png =  File.dirname(__FILE__) + "/../fixtures/image1.png"
    @test_img_gif =  File.dirname(__FILE__) + "/../fixtures/image1.gif"
    @test_img_fake = File.dirname(__FILE__) + "/../fixtures/image1_fake.jpg"
    @test_img_remote_png = "https://example.com/sample-image.png"
    @test_img_remote_fake = "invalid_URI"
    @image = ws.add_image :image_src => @test_img, :hyperlink => 'https://github.com/randym', :tooltip => "What's up doc?", :opacity => 5
    @image_remote = ws.add_image :image_src => @test_img_remote_png, remote: true, :hyperlink => 'https://github.com/randym', :tooltip => "What's up doc?", :opacity => 5
  end

  def test_initialization
    assert_equal(@p.workbook.images.first, @image)
    assert_equal(@image.file_name, 'image1.jpeg')
    assert_equal(@image.image_src, @test_img)
  end

  def test_remote_img_initialization
    assert_equal(@p.workbook.images[1], @image_remote)
    assert_equal(@image_remote.file_name, nil)
    assert_equal(@image_remote.image_src, @test_img_remote_png)
    assert_equal(@image_remote.remote?, true)
  end

  def test_anchor_swapping
    # swap from one cell to two cell when end_at is specified
    assert(@image.anchor.is_a?(Axlsx::OneCellAnchor))
    start_at = @image.anchor.from
    @image.end_at 10, 5
    assert(@image.anchor.is_a?(Axlsx::TwoCellAnchor))
    assert_equal(start_at.col, @image.anchor.from.col)
    assert_equal(start_at.row, @image.anchor.from.row)
    assert_equal(10, @image.anchor.to.col)
    assert_equal(5, @image.anchor.to.row)

    # swap from two cell to one cell when width or height are specified
    @image.width = 200
    assert(@image.anchor.is_a?(Axlsx::OneCellAnchor))
    assert_equal(start_at.col, @image.anchor.from.col)
    assert_equal(start_at.row, @image.anchor.from.row)
    assert_equal(200, @image.width)
  end

  def test_hyperlink
    assert_equal(@image.hyperlink.href, "https://github.com/randym")
    @image.hyperlink = "http://axlsx.blogspot.com"
    assert_equal(@image.hyperlink.href, "http://axlsx.blogspot.com")
  end

  def test_name
    assert_raise(ArgumentError) { @image.name = 49 }
    assert_nothing_raised { @image.name = "unknown" }
    assert_equal(@image.name, "unknown")
  end

  def test_start_at
    assert_raise(ArgumentError) { @image.start_at "a", 1 }
    assert_nothing_raised { @image.start_at 6, 7 }
    assert_equal(@image.anchor.from.col, 6)
    assert_equal(@image.anchor.from.row, 7)
  end

  def test_width
    assert_raise(ArgumentError) { @image.width = "a" }
    assert_nothing_raised { @image.width = 600 }
    assert_equal(@image.width, 600)
  end

  def test_height
    assert_raise(ArgumentError) { @image.height = "a" }
    assert_nothing_raised { @image.height = 600 }
    assert_equal(600, @image.height)
  end

  def test_image_src
    assert_raise(ArgumentError) { @image.image_src = __FILE__ }
    assert_raise(ArgumentError) { @image.image_src = @test_img_fake }
    assert_nothing_raised { @image.image_src = @test_img_gif }
    assert_nothing_raised { @image.image_src = @test_img_png }
    assert_nothing_raised { @image.image_src = @test_img_jpg }
    assert_equal(@image.image_src, @test_img_jpg)
  end

  def test_remote_image_src
    assert_raise(ArgumentError) { @image_remote.image_src = @test_img_fake }
    assert_raise(ArgumentError) { @image_remote.image_src = @test_img_remote_fake }
    assert_nothing_raised { @image_remote.image_src = @test_img_remote_png }
    assert_equal(@image_remote.image_src, @test_img_remote_png)
  end

  def test_descr
    assert_raise(ArgumentError) { @image.descr = 49 }
    assert_nothing_raised { @image.descr = "test" }
    assert_equal(@image.descr, "test")
  end

  def test_to_xml
    schema = Nokogiri::XML::Schema(File.open(Axlsx::DRAWING_XSD))
    doc = Nokogiri::XML(@image.anchor.drawing.to_xml_string)
    errors = []
    schema.validate(doc).each do |error|
      errors.push error
      puts error.message
    end
    assert(errors.empty?, "error free validation")
  end

  def test_to_xml_has_correct_r_id
    r_id = @image.anchor.drawing.relationships.for(@image).Id
    doc = Nokogiri::XML(@image.anchor.drawing.to_xml_string)
    assert_equal r_id, doc.xpath("//a:blip").first["r:embed"]
  end
end
