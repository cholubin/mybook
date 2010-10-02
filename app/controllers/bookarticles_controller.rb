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
    
    puts_message @article.title + " Updated!"
    
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
    pid = `ps -c -eo pid,comm | grep MLayout`.to_s
    puts_message pid
    if pid != ""
      pid = pid.gsub(/MLayout 2/,'').gsub(' ', '')
      system "kill #{pid}"           
    end
    
    
    start_page = params[:start_page]

    puts_message start_page
    #마스터템플릿 아이디와 현재선택된 템플릿 구분을 참고하여 복사할대상으로 삼는다.
    master_template_info = params[:temp_id].split('.')
    master_template_id = master_template_info[0]
    template_name = master_template_info[1] #gubun or inner_cover ...
    
    #현재작업중인 책의 아이디 
    book_id = params[:book_id]
    
    #현재작업중인 꼭지의 아이디 
    book_level_id = params[:level_id]
    
    #book_article 폴더가 없으면 생성하고 해당 폴더 밑으로 현재작업중인 책의 아이디로 폴더를 만든다.
    book_article_dir = "#{RAILS_ROOT}" + "/public/user_files/#{current_user.userid}/book_article/#{book_id}/"
    if !File.exist?(book_article_dir)
     FileUtils.mkdir_p book_article_dir
    end
    
    #작업에 필요한 템플릿을 book_article폴더로 복사해넣는다. 그전에 작업한 녀석은 그대로 삭제하고 붙여넣는다.
    
    #본문 템플릿인 경우 (본문 템플릿을 마스터로 잡아 폴더밖에 있기 때문.)
    if template_name == "body_l"
      #복사대상 
      src_path = "#{RAILS_ROOT}" + "/public/user_files/#{current_user.userid}/article_templates/"
      src_filename = master_template_id + ".mlayoutP"

      dest_path = book_article_dir
      dest_filename = book_id + "." + book_level_id + ".mlayoutP"
      
    #본문외의 것들인 경우 
    else
      #복사대상 
      src_path = "#{RAILS_ROOT}" + "/public/user_files/#{current_user.userid}/article_templates/#{master_template_id}/"      
      src_filename = master_template_id + template_name + ".mlayoutP"

      dest_path = book_article_dir      
      dest_filename = book_id + "." + book_level_id + "." + template_name + ".mlayoutP"      
    end
    
    puts_message dest_path + dest_filename
    if File.exist?(dest_path + dest_filename)
      FileUtils.rm_rf dest_path + dest_filename
      FileUtils.cp_r src_path + src_filename, dest_path + dest_filename
    else
      FileUtils.cp_r src_path + src_filename, dest_path + dest_filename
    end
    

    
    #복사된 템플릿을 Mjob 처리해준다.
    
    if Mytemplate.all(:name => dest_filename, :gubun => "hidden").count < 1
      begin
        puts_message "Here????"
        booktemplate = Mytemplate.new()  
        booktemplate.gubun = "hidden"
        booktemplate.path = dest_path + dest_filename
        booktemplate.is_book = true
        booktemplate.name = dest_filename
        booktemplate.master_id = master_template_id
        booktemplate.user_id = current_user.id
        booktemplate.level_id = book_level_id
        booktemplate.save
      rescue
        puts_message "errrrrrrrrrrrrrrrorrrrrrrrr"
      end
    else
      puts_message "or Here????"      
      booktemplate = Mytemplate.first(:name => dest_filename, :gubun => "hidden")
      booktemplate.path = dest_path + dest_filename
      booktemplate.name = dest_filename
      booktemplate.master_id = master_template_id
      booktemplate.user_id = current_user.id      
      booktemplate.level_id = book_level_id      
      booktemplate.save
    end
    make_contens_xml(booktemplate)
    
    contents_xml_path =  dest_path + dest_filename + "/web/contents.xml"
    loop do
      puts_message "content.xml 생성 체크!!!!!!!!"
      break if File.exists?(contents_xml_path)
    end
    
    make_xml_contents(booktemplate, book_level_id)

    if File.exists?(booktemplate.path + "/web/contents.xml2")
      FileUtils.rm_rf booktemplate.path + "/web/contents.xml"
      File.rename booktemplate.path + "/web/contents.xml2", booktemplate.path + "/web/contents.xml" 
    end
    
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
     	<string>#{booktemplate.id}</string>    	
    </dict>
    </plist>

    EOF

    job_done = booktemplate.path + "/web/done.txt" 
    
    if File.exists?(job_done)
      FileUtils.rm_rf job_done      
    end
    
    njob = booktemplate.path + "/refreshxml_job.mJob" 
    File.open(njob,'w') { |f| f.write xml_file }    
    system "open #{njob}"

    

    
    puts_message "creating M file!!!"

    time_after_180_seconds = Time.now + 180.seconds     
    while Time.now < time_after_180_seconds
    # loop do
      break if File.exists?(job_done)
      # puts_message "XML파일 업데이트중............"
    end

    if !File.exists?(job_done)
      pid = `ps -c -eo pid,comm | grep MLayout`.to_s
      pid = pid.gsub(/MLayout 2/,'').gsub(' ', '')
      system "kill #{pid}"     
      puts_message "MLayout was killed!!!!! ============"
    else
      puts_message "There is job done file of M file making!"
    end
    
    if start_page != ""
      make_start_page(booktemplate, start_page)
    end
    
    puts_message "publish_mjob end"               
    
    @temp = booktemplate
    @book_id = book_id
    # render :partial => "mlayout_run"
    render :update do |page|
      page.replace_html 'mlayout_run', :partial => 'mlayout_run', :object => @temp, :object => @book_id
    end    
  end

  def make_start_page(booktemplate,start_page)
    xml_file = <<-EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>Action</key>
    	<string>SetPageNumber</string>
    	<key>DocPath</key>
    	<string>#{booktemplate.path}</string>   
    	<key>ID</key>
     	<string>#{booktemplate.id}</string>    	
      <key>UserInfo</key>
      <string>#{start_page}</string>     	
    </dict>
    </plist>

    EOF

    job_done = booktemplate.path + "/web/done.txt" 
    if File.exists?(job_done)
      FileUtils.rm_rf job_done      
    end
    
    njob = booktemplate.path + "/publish_job.mJob" 
    File.open(njob,'w') { |f| f.write xml_file }    
    system "open #{njob}"


    puts_message "creating Start Page!!!!!!!!"

    time_after_10_seconds = Time.now + 10.seconds     
    while Time.now < time_after_10_seconds
    # loop do
      break if File.exists?(job_done)
      # puts_message " 시작페이지 넣는 중......"
    end    
    
    if !File.exists?(job_done)
      pid = `ps -c -eo pid,comm | grep MLayout`.to_s
      pid = pid.gsub(/MLayout 2/,'').gsub(' ', '')
      system "kill #{pid}"     
      puts_message "MLayout was killed!!!!! ============"
    else
      puts_message "There is job done file of M file making!"
    end

    
  end
  
  def make_xml_contents(book_template, level_id)
    
puts_message "make_xml_contents 함수 진행중 ........."
puts_message "현재 작업중인 텍스트박스 아이디: " + level_id

    erase_job_done_file(book_template)
    
    article_content = Book_article.get(level_id.to_i).content

puts_message "현재 작업중인 텍스트박스 컨텐츠: " + article_content
    
    xml_file = <<-EOF
<xml>#{article_content}</xml>
    EOF

    path = book_template.path
    write_2_file =  path + "/web/contents.xml2"      
    
    begin
      if File.exist?(write_2_file)
        FileUtils.rm_rf write_2_file
        
puts_message "contents.xml 삭제 성공!"
      else
puts_message "contents.xml 지울 파일이 없다네 !"        
      end
      
    rescue
      puts_message "contents.xml 삭제 실패! 먼지모를 에러 발생!!!"      
    end
    
puts_message "저장할 contents.xml 파일 경로: " + write_2_file

    begin
      File.open(write_2_file,'w') { |f| f.write xml_file }
    rescue
      puts_message "여기서 일단 에러 난다니까!!!"
    end
    
    time_after_5_seconds = Time.now + 5.seconds     
    while Time.now < time_after_5_seconds
    # loop do
    #   break if File.exists?(write_2_file)
    end

    puts_message "make_xml_contents 함수 작업완료!"
        
  end


  def make_contens_xml(temp) 
    erase_job_done_file(temp)
    path = temp.path

    mjob_file= <<-EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>Action</key>
    	<string>MakeContentsXML</string>
    	<key>DocPath</key>
    	<string>#{path}</string>   
     <key>ID</key>
    	<string>#{temp.id}</string>     	
    </dict>
    </plist>
    </xml>
    EOF
    

     mjob = path + "/do_job.mJob" 
     
 
     
     File.open(mjob,'w') { |f| f.write mjob_file }    

    if File.exists?(mjob)
        system "open #{mjob}"
    end 
    
    time_after_30_seconds = Time.now + 30.seconds     
    thumb_path = "#{RAILS_ROOT}/public#{temp.thumb_url}"
    puts_message thumb_path
    puts_message "waiting for thumnail image!"    
    
    # while Time.now < time_after_30_seconds
    loop do
      break if File.exists?(thumb_path)
    end
           
    puts_message "make_contens_xml finished"
  end

  def erase_job_done_file(temp)        
    job_done = temp.path + "/web/done.txt" 
    if File.exists?(job_done) then
      FileUtils.remove_entry(job_done)
    end
    puts_message "erase_job_done_file"
  end

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
