require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'cgi'

describe MarcDisplay::MarcToOpenUrl do

  describe "for nil marc record" do
    it "should return nil" do
      marcToOpenUrl = MarcDisplay::MarcToOpenUrl.new(nil)
      marcToOpenUrl.build_openurl.should be_nil
    end
  end
  
  describe "for a book marc record" do
    before(:all) do
      @marcToOpenUrl = MarcDisplay::MarcToOpenUrl.new(chomsky_book_marc)      
      @context_object = @marcToOpenUrl.build_openurl
      @co_kev_hash = CGI.parse( @context_object.kev)
    end

    it "should be book OpenURL format" do
      @co_kev_hash["rft_val_fmt"].should == ["info:ofi/fmt:kev:mtx:book"]
    end

    it "should have rft.genre of book" do
      @co_kev_hash["rft.genre"].should == ["book"]
    end
      
    it "should create author" do      
      @co_kev_hash["rft.au"].should == ["Chomsky, Noam"]
    end
    it "should create title as btitle" do      
      @co_kev_hash["rft.btitle"].should ==["Perilous power: the Middle East & U.S. foreign policy : dialogues on terror, democracy, war, and justice"]
      @co_kev_hash.keys.should_not include("rft.title")
    end
    it "should have date" do
      @co_kev_hash["rft.date"].should == ["2007"]
    end
    it "should have isbn" do      
      @co_kev_hash["rft.isbn"].should == ["1594513120"]
    end
    it "should include oclcnum rft_id" do
      @co_kev_hash["rft_id"].should include("info:oclcnum/70630340")
    end
    it "should include lccn rft_id" do
      @co_kev_hash["rft_id"].should include("info:lccn/2006021980")
    end
    it "should include place" do      
      @co_kev_hash["rft.place"].should == ["Boulder"]
    end
    it "should include publisher" do      
      @co_kev_hash["rft.pub"].should == ["Paradigm Publishers"]
    end
    it "should have total pages" do
      @co_kev_hash["rft.tpages"].should == ["276"]
    end
  end

  describe "for a journal marc record" do
    before(:all) do
      @marcToOpenUrl = MarcDisplay::MarcToOpenUrl.new(social_journal_marc)      
      @context_object = @marcToOpenUrl.build_openurl
      @co_kev_hash = CGI.parse( @context_object.kev)
    end
    it "should be journal OpenURL format" do
      @co_kev_hash["rft_val_fmt"].should == ["info:ofi/fmt:kev:mtx:journal"]
    end

    it "should have rft.genre of journal" do
      @co_kev_hash["rft.genre"].should == ["journal"]
    end

    it "should have no author" do
      @co_kev_hash.keys.should_not include("rft.au")
    end

    it "should have ISSN" do
      @co_kev_hash["rft.issn"].should == ["17512395"]
    end

    it "should have title as jtitle" do
      @co_kev_hash["rft.jtitle"].should == ["Social issues and policy review"]
      @co_kev_hash.keys.should_not include("rft.title")
    end

    it "should have OCLCnum in rft_id" do
      @co_kev_hash["rft_id"].should include("info:oclcnum/190564913")
    end
    
  end
  
  def chomsky_book_marc
    reader = MARC::Reader.new("#{MARC_DATA_PATH}/chomsky.mrc")
    reader.each do |marc|
      return marc
    end
    return nil
  end

  def social_journal_marc
    reader = MARC::Reader.new("#{MARC_DATA_PATH}/social_journal.mrc")
    reader.each do |marc|
      return marc
    end
    return nil
  end

end

