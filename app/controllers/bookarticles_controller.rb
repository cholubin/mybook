# encoding: utf-8

class BookarticlesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @menu = "myarticles"
    @book_id = params[:book_id]
    
    if !@book_id.nil?
      @book_basic = Book_basic.get(@book_id.to_i)
    else
      
    end
    render 'bookarticle'  
  end
  


  # PUT /articles/1
  # PUT /articles/1.xml
  def update
    @article = Book_article.get(params[:id].to_i)
    
    @article.title = params[:title]
    @article.content = params[:content]
    
    puts_message @article.title 
    puts_message @article.content 
    
    if @article.save
      render :partial => "result"    
    end
  end

  def left_list_delete
    
    book_id = params[:book_id].to_i

    @book_basic = Book_basic.first(:id => book_id, :user_id => current_user.id)
    @book_articles = Book_article.all(:book_basic_id => book_id, :user_id => current_user.id)
    
    if params[:need_reload] == "true"
      @need_reload = true
    else
      @need_reload = false
    end
    

    tmp_msg = "on deleting "+@book_basic.title+"'s articles: total "+@book_articles.count.to_s+" articles ..."    
    puts_message tmp_msg

    if @book_basic.destroy 
      if @book_articles.destroy
        @book_list = Book_basic.all(:user_id => current_user.id)
      else
        puts_message "error occured on progress of deleting Book_articles table..."        
      end

      render :partial => "new_book_list", :object => @book_list, :object => @need_reload
      # render 'bookarticle'
    else
      puts_message "error occured on progress of deleting Book_basic table..."
    end
  end

  def publish_book
    
    booktemplate = Mytemplate.first(:name => "Book sample")  
    article_id = params[:article_id]
    
    puts_message booktemplate.path
    puts_message article_id
    
    make_xml_contents(booktemplate, article_id)
    
    goal = booktemplate.path    
    puts_message goal
    
    xml_file = <<-EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>Action</key>
    	<string>RefreshXML</string>
    	<key>DocPath</key>
    	<string>#{goal}</string>   
    	<key>ID</key>
     	<string>#{booktemplate.temp_id}</string>    	
    </dict>
    </plist>

    EOF

    njob = booktemplate.path + "/publish_job.mJob" 
    File.open(njob,'w') { |f| f.write xml_file }    
    system "open #{njob}"

    job_done = booktemplate.path + "/web/done.txt" 

    puts_message "creating M file!!!"

    time_after_180_seconds = Time.now + 180.seconds     
    while Time.now < time_after_180_seconds
      break if File.exists?(job_done)
    end

    if !File.exists?(job_done)
      pid = `ps -c -eo pid,comm | grep MLayout`.to_s
      pid = pid.gsub(/MLayout 2/,'').gsub(' ', '')
      system "kill #{pid}"     
      puts_message "MLayout was killed!!!!! ============"
    else
      puts_message "There is job done file of M file making!"
    end

    puts_message "publish_mjob end"               
    
    @temp = booktemplate
    
    # render :partial => "mlayout_run"
    render :update do |page|
      page.replace_html 'mlayout_run', :partial => 'mlayout_run', :object => @temp
    end    
  end

  
  def make_xml_contents(mytemplate, article_id)
    
    article_content = Book_article.get(article_id.to_i).content

    xml_file = <<-EOF
    <xml>
      #{article_content}
    </xml>
    EOF

    path = mytemplate.path
    write_2_file =  path + "/web/contents.xml"      
    File.open(write_2_file,'w') { |f| f.write xml_file }
    
  end
  # DELETE /articles/1
  # DELETE /articles/1.xml
  def destroy
    @article = Article.get(params[:id])
    
    # 업로드된 이미지 파일 삭제 =========================================================================
    file_name = @article.image_filename
    if  File.exist?(IMAGE_PATH + file_name)
      	File.delete(IMAGE_PATH + file_name)         #original image file
      	File.delete(IMAGE_PATH + "t_" + file_name)  #thumbnail file
    end
    # 업로드된 이미지 파일 삭제 =========================================================================
    @article.destroy

    respond_to do |format|
      format.html { redirect_to(articles_url) }
      format.xml  { head :ok }
    end
  end
  
end
