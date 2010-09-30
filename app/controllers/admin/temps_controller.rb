# encoding: utf-8
require 'zip/zip'
require 'zip/zipfilesystem'

class Admin::TempsController < ApplicationController
  layout 'admin_layout'
  # GET /temps
  # GET /temps.xml
  def index
    
    # @temp = Temp.first(:id => 2)
    #    @temp.destroy
    
    @category_name = params[:category_name]
    @subcategory_name = params[:subcategory_name]
    
    sort = params[:sort]
    if sort == nil
      sort = "all"
    end
    
    if sort == "all"
      @temps = Temp.all.search2(params[:search], params[:page])      
      @total_count = Temp.search2(params[:search],"").count    
    else
      @temps = Temp.all(:category => sort).search2(params[:search], params[:page])      
      @total_count = Temp.all(:category => sort).search2(params[:search],"").count    
    end
          
    @categories = Category.all(:order => :priority)    
    
    @menu = "template"
    @board = "temp"
    @section = "index"
    
    render 'temp'  
  end

  def update_subcategories
      # updates subcategories based on (main)category selected
      
      categories = Category.first(:name => params[:category_id])
      subcategories = categories.subcategories

      # puts subcategories.inspect

      render :update do |page|
        page.replace_html 'subcategories', :partial => 'subcategories', :object => subcategories
      end
  end
  
  # GET /temps/1
  # GET /temps/1.xml
  def show
    @menu = "template"
    @board = "temp"
    @section = "show"
    
    @categories = Category.all(:order => :priority)   
    @temp = Temp.get(params[:id])
    
    @category_name = @temp.category
    @subcategory_name = @temp.subcategory
    render 'temp'
  end

  # GET /temps/new
  # GET /temps/new.xml
  def new
    @menu = "template"
    @board = "temp"
    @section = "new"
        
    @temp = Temp.new
    @categories = Category.all(:order => :priority)    
    @subcategories = Subcategory.all(:order => :priority)
    
     render 'temp'
  end

  # GET /temps/1/edit
  def edit
    @menu = "template"
    @board = "temp"
    @section = "edit"
        
    @temp = Temp.get(params[:id])
    
    render 'temp'
  end


  def book_basic_process(temp, param1)
    if @temp.save
      file_name_by_id = @temp.id.to_s
    end
    
    @temp.file = param1  if param1
    @temp.original_filename = param1.original_filename
    # @temp.file_filename = sanitize_filename(@temp.original_filename) if params[:temp][:file]
    @temp.file_filename = file_name_by_id + ".mlayoutP.zip"
    @temp_filename = @temp.filename

    @extname = ".mlayoutP.zip"

    @temp.file_filename = @temp_filename
    @temp.file_filename_encoded = @temp.file.filename

    @temp.zip_file = "#{RAILS_ROOT}/public/templates/" + @temp.file_filename  if param1
    @temp.path = "#{RAILS_ROOT}" + "/public/templates/" + @temp.file_filename.gsub(/.zip/,'')  if param1    
    @temp.type = "template"

    @temp.thumb_url = "/templates/" + @temp.filename.gsub(/.zip/,'') + "/web/doc_thumb.jpg"         
    @temp.preview_url = "/templates/" + @temp.filename.gsub(/.zip/,'') + "/web/doc_preview.jpg"    
    
    respond_to do |format|
      if @temp.save
        
        # filename renaming ======================================================================
        file_path = @temp.file_path
        file_name = @temp.file_filename_encoded
        
        if file_name

         if  File.exist?(file_path + file_name)
          	File.rename file_path + file_name, file_path  + @temp.file_filename #original file
          	@temp.zip_file = file_path  + @temp.file_filename
          end
        end      
        # filename renaming ======================================================================
                
        begin
          unzip_uploaded_file(@temp)
          puts_message "unzip_uploaded_file finished!"
          
          make_contens_xml(@temp) 
          puts_message "make_contens_xml finished!"
                    
          erase_job_done_file(@temp)
          puts_message "erase_job_done_file finished!"
                  
          flash[:notice] = 'Temp was successfully created.'
          format.html { redirect_to admin_temps_path }
        rescue
          flash[:notice] = "failed to upload."  
          puts "\n============================== \n error while processing \n ============================== \n"
          #           
        end
      else
        @board = "temp"
        @section = "new"
        format.html { render :action => "new" }
      end
    end    
  end

  def create

    @temp = Temp.new(params[:temp])

    if @temp.save
      file_name_by_id = @temp.id.to_s
    end
          
    if params[:temp][:is_book] == "1"
      
      begin
        new_dir = TEMP_PATH + file_name_by_id + "/"
        if !File.exist?(new_dir)
         FileUtils.mkdir_p new_dir
         FileUtils.chmod 0777, new_dir
        end
                
        uploader = MlayoutTemplateUploader.new
        uploader.store!(params[:temp][:inner_cover])
        uploader.store!(params[:temp][:index])        
        uploader.store!(params[:temp][:dobira])
        
        file_path = @temp.file_path
        
        #한글문제 처리해야 한다!!!
        File.rename file_path + params[:temp][:inner_cover].original_filename, new_dir  + file_name_by_id + "inner_cover" + ".mlayoutP.zip"        
        File.rename file_path + params[:temp][:index].original_filename, new_dir  + file_name_by_id + "index" + ".mlayoutP.zip"                
        File.rename file_path + params[:temp][:dobira].original_filename, new_dir  + file_name_by_id + "dobira" + ".mlayoutP.zip"                
        

        unzip(new_dir+file_name_by_id+"inner_cover"+".mlayoutP.zip",new_dir,params[:temp][:inner_cover].original_filename.gsub(/.zip/,''),file_name_by_id + "inner_cover" + ".mlayoutP")    
        unzip(new_dir+file_name_by_id+"index"+".mlayoutP.zip",new_dir,params[:temp][:index].original_filename.gsub(/.zip/,''),file_name_by_id + "index" + ".mlayoutP")    
        unzip(new_dir+file_name_by_id+"dobira"+".mlayoutP.zip",new_dir,params[:temp][:dobira].original_filename.gsub(/.zip/,''),file_name_by_id + "dobira" + ".mlayoutP")    
        
        # unzip(file, destination, original_filename, modified_filename)
        
      rescue
        puts_message "에러나버렸잖어!!!!!!!!!!!!!!!!!!!!!!!!!!"
      end
    end

    
    @temp.file = params[:temp][:file]  if params[:temp][:file]
    @temp.original_filename = params[:temp][:file].original_filename
    # @temp.file_filename = sanitize_filename(@temp.original_filename) if params[:temp][:file]
    @temp.file_filename = file_name_by_id + ".mlayoutP.zip"
    @temp_filename = @temp.filename

    @extname = ".mlayoutP.zip"

    @temp.file_filename = @temp_filename
    @temp.file_filename_encoded = @temp.file.filename

    @temp.zip_file = "#{RAILS_ROOT}/public/templates/" + @temp.file_filename  if params[:temp][:file]
    @temp.path = "#{RAILS_ROOT}" + "/public/templates/" + @temp.file_filename.gsub(/.zip/,'')  if params[:temp][:file]    
    @temp.type = "template"

    @temp.thumb_url = "/templates/" + @temp.filename.gsub(/.zip/,'') + "/web/doc_thumb.jpg"         
    @temp.preview_url = "/templates/" + @temp.filename.gsub(/.zip/,'') + "/web/doc_preview.jpg"
    
            
    if params[:temp][:is_book] == "1"
      # 북템플릿 처리 
      @temp.is_book = true
      @temp.is_master = true
      @temp.gubun = "master"
      @temp.master_id = file_name_by_id.to_i
      
      master_book_template_process(@temp)
    else
      # 일반템플릿 처리 
      basic_template_process(@temp)
    end      
  end

  def master_book_template_process(temp)
    @temp = temp
    respond_to do |format|
      if @temp.save
        
        # 원플러스용 사용자별 템플릿 공개 혀용여부에 따른 처리루틴 =====================
        if TEMPLATE_OPEN_FUNC_TOGGLE == true
          temp_id = @temp.id
          user_list = params[:user_list].split(',')

          if !user_list.nil? 
            # 먼저 해당템플릿에 대해 공개허용된 사용자정보를 삭제한다. 
            user_open_all = Usertempopenlist.all(:temp_id => temp_id)
            if !user_open_all.nil?
              user_open_all.destroy
            end
            # 새롭게 사용자별로 허용한다.  
            user_list.each do |u|
              usertemp = Usertempopenlist.new()
              usertemp.user_id = u
              usertemp.temp_id = temp_id
              usertemp.save
            end
          end
        end

        
        # filename renaming ======================================================================
        file_path = @temp.file_path
        file_name = @temp.file_filename_encoded
        
        if file_name

          if File.exist?(file_path + file_name)
          	File.rename file_path + file_name, file_path  + @temp.file_filename #original file
          	@temp.zip_file = file_path  + @temp.file_filename
          end
        end      
        # filename renaming ======================================================================
                
        begin
          unzip_uploaded_file(@temp)
          puts_message "unzip_uploaded_file finished!"
          
          make_contens_xml(@temp) 
          puts_message "make_contens_xml finished!"
                    
          erase_job_done_file(@temp)
          puts_message "erase_job_done_file finished!"
                  
          flash[:notice] = 'Temp was successfully created.'
          format.html { redirect_to admin_temps_path }
        rescue
          flash[:notice] = "failed to upload."  
          puts "\n============================== \n error while processing \n ============================== \n"
          redirect_to admin_temps_path          
        end
      else
        @board = "temp"
        @section = "new"
        format.html { render :action => "new" }
      end
    end    
  end
  
  def basic_template_process(temp)
    @temp = temp
    respond_to do |format|
      if @temp.save
        
        # 원플러스용 사용자별 템플릿 공개 혀용여부에 따른 처리루틴 =====================
        if TEMPLATE_OPEN_FUNC_TOGGLE == true
          temp_id = @temp.id
          user_list = params[:user_list].split(',')

          if !user_list.nil? 
            # 먼저 해당템플릿에 대해 공개허용된 사용자정보를 삭제한다. 
            user_open_all = Usertempopenlist.all(:temp_id => temp_id)
            if !user_open_all.nil?
              user_open_all.destroy
            end
            # 새롭게 사용자별로 허용한다.  
            user_list.each do |u|
              usertemp = Usertempopenlist.new()
              usertemp.user_id = u
              usertemp.temp_id = temp_id
              usertemp.save
            end
          end
        end

        
        # filename renaming ======================================================================
        file_path = @temp.file_path
        file_name = @temp.file_filename_encoded
        
        if file_name

         if  File.exist?(file_path + file_name)
          	File.rename file_path + file_name, file_path  + @temp.file_filename #original file
          	@temp.zip_file = file_path  + @temp.file_filename
          end
        end      
        # filename renaming ======================================================================
                
        begin
          unzip_uploaded_file(@temp)
          puts_message "unzip_uploaded_file finished!"
          
          make_contens_xml(@temp) 
          puts_message "make_contens_xml finished!"
                    
          erase_job_done_file(@temp)
          puts_message "erase_job_done_file finished!"
                  
          flash[:notice] = 'Temp was successfully created.'
          format.html { redirect_to admin_temps_path }
        rescue
          flash[:notice] = "failed to upload."  
          puts "\n============================== \n error while processing \n ============================== \n"
          redirect_to admin_temps_path          
        end
      else
        @board = "temp"
        @section = "new"
        format.html { render :action => "new" }
      end
    end    
  end
  


  def update
    @menu = "template"
    @board = "temp"
    @section = "edit"
    temp_id = params[:id].to_i    
    @temp = Temp.get(temp_id)
    
    user_list = params[:user_list].split(',')

    if !user_list.nil? 
      # 먼저 해당템플릿에 대해 공개허용된 사용자정보를 삭제한다. 
      user_open_all = Usertempopenlist.all(:temp_id => temp_id)
      if !user_open_all.nil?
        user_open_all.destroy
      end
      # 새롭게 사용자별로 허용한다.  
      user_list.each do |u|
        usertemp = Usertempopenlist.new()
        usertemp.user_id = u
        usertemp.temp_id = temp_id
        usertemp.save
      end
    end
        
    @temp.name = params[:temp][:name]
    @temp.size = params[:temp][:size]
    @temp.price = params[:temp][:price]
    
    if @temp.save
      redirect_to admin_temp_url
    else
      render 'temp'
    end

  end

  # DELETE /temps/1
  # DELETE /temps/1.xml

  
    def get_img_tags
      @tp = Temp.find_by_id(params[:id])
      @tp.included_images  
      render :json => @tp.included_images
      # render :text => @tp.included_images    
    end 



    def destroy
      @temp = Temp.get(params[:id])

      if @temp != nil
        if File.exist?(TEMP_PATH + @temp.file_filename) 
          File.delete(TEMP_PATH + @temp.file_filename)   
          FileUtils.rm_rf TEMP_PATH + @temp.file_filename.gsub(/.zip/,'')
        end
      end
      
      temp_id = @temp.id
      if @temp.destroy
        usertempopenlist = Usertempopenlist.all(:temp_id => temp_id)
        usertempopenlist.destroy
      end

      respond_to do |format|
        format.html { redirect_to(temps_url) }
        format.xml  { head :ok }
      end
    end

    def deleteSelection 

      chk = params[:chk]

      if !chk.nil? 
        chk.each do |chk|
          @temp = Temp.get(chk[0].to_i)

          if @temp != nil
            if File.exist?(TEMP_PATH + @temp.file_filename) 
              File.delete(TEMP_PATH + @temp.file_filename)   
            end
            
            if File.exist?(@temp.path) 
                # FileUtils.rm_rf @temp.path ==> 인코딩때문에 삭제되지 않는다!
                # File의 경우 상관없으나 FileUtils의 경우 인코딩처리를 해줘야 한다.
                FileUtils.rm_rf @temp.path.force_encoding('UTF8-MAC')                 
            end
          end
          temp_id = @temp.id
          if @temp.destroy
            usertempopenlist = Usertempopenlist.all(:temp_id => temp_id)
            usertempopenlist.destroy
          end  
        end

      else
          flash[:notice] = '삭제할 글을 선택하지 않으셨습니다!'    
      end

      redirect_to(admin_temps_url)  
     end




    private   

    def check_done_txt(temp)
       done_txt = temp.path + "/web/done.txt"

      loop do 
         break if File.exists?(done_txt)

      end    
      
      puts_message "check_done_txt"
      
    end       

    def make_done_txt(temp)
  content= <<-EOF   
  #{temp.id}
  OK   
  EOF

      done_txt_file = (temp.path + "/web/done.txt") 
      File.open(done_txt_file,'w') { |f| f.write content }    
      puts_message "make_done_txt finished"          
    end     

    def check_jpg_and_process_thumbnail(temp)                
       
     check_done_txt(temp) 
     erase_job_done_file(temp)
     # puts "done txt process image"
     process_index_thumbnail(temp)
     # puts "start count image"    
     count_images(temp)      
     # puts "closing your doc"     
      make_done_txt(temp) 

    end

     def close_document(temp)  
       # check_done_txt(temp)  
     erase_job_done_file(temp)     
      close_xml= <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      	<key>Action</key>
      	<string>CloseDocument</string>
      	<key>DocPath</key>
      	<string>#{temp.path}</string> 
        <key>ID</key>
       	<string>#{temp.id}</string>    	         	
      </dict>
      </plist>

      EOF
      close_job_file = (temp.path + "/close_job.mJob") 
      File.open(close_job_file,'w') { |f| f.write close_xml } 
      system "open #{close_job_file}"
    end

     def find_user
       @user = current_user    
     end  

     def erase_job_done_file(temp)        
       job_done = temp.path + "/web/done.txt" 
       if File.exists?(job_done) then
         FileUtils.remove_entry(job_done)
       end
       puts_message "erase_job_done_file"
     end

  
  def unzip_uploaded_file(template) 
   if template != nil   
     destination = TEMP_PATH
     
     loop do 
        break if File.exists?(template.zip_file)
     end
     
     begin              
       unzip(template.zip_file, destination, template.original_filename.gsub(/.zip/,''), template.file_filename.gsub(/.zip/,''))    
       path = TEMP_PATH + template.file_filename.gsub(/.zip/,'')         
       mjob_filename = path + "/do_job.mjob"  
      rescue          
       puts_error "Template unzip process was failed!"    
      end  
                 
     end
   end  
   
 
   def unzip(file, destination, original_filename, modified_filename)  
     
     begin

       osx_tmp_path = TEMP_PATH + "__MACOSX"
       
       if original_filename != modified_filename
         destination_temp = destination + "temp/"
         renaming_needed = true
       end
              
       Zip::ZipFile.open(file) { |zip_file|
         zip_file.each{ |f| 

           if renaming_needed
              f_path = File.join(destination_temp, f.name)
           else
              f_path = File.join(destination, f.name)
           end

           FileUtils.mkdir_p(File.dirname(f_path))
           zip_file.extract(f, f_path) unless File.exist?(f_path)
         }
       }

       if  renaming_needed && File.exist?(destination_temp + original_filename)
        	File.rename destination_temp + original_filename, destination  + modified_filename
          FileUtils.rm_rf destination_temp
        else
          FileUtils.rm_rf osx_tmp_path
       end
               
     rescue
      puts "An error occurred during unzip process"
     end     
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
    
    while Time.now < time_after_30_seconds
      break if File.exists?(thumb_path)
    end
           
    puts_message "make_contens_xml finished"
  end
  
  def count_images(temp)       
    begin
      doc = File.open(temp.path + "/web/contents.xml")
      xml_doc = Nokogiri::XML(doc)
      array = []
      for n in 1 .. 50
        if xml_doc.search('image_' + n.to_s).count == 1
          array << n
        end
      end 
      temp.included_images = array
      temp.save
      doc.close 
    rescue                       
      flash[:notice] = "failed to read templates' contents file"  
      
    end  
  end
      
  def copy_template
    temp_id = params[:id]                           
    path = "#{RAILS_ROOT}/public/user_files/" + current_user.userid + "/templates"
    @object_to_clone = Temp.get(temp_id) 
    puts @object_to_clone.id
    @cloned_object = Mytemplate.new
    @cloned_object.name = @object_to_clone.name
    @cloned_object.file_filename = @object_to_clone.file_filename
    puts @cloned_object.file_filename
    
    @cloned_object.description = @object_to_clone.description
    @cloned_object.temp_id = temp_id 
    @cloned_object.user_id = current_user.id
    mytemplate_filename = @object_to_clone.file_filename.gsub(/.zip/,'')
    
    @cloned_object.thumb_url = "/user_files/" + current_user.userid + "/templates/" +  mytemplate_filename + "/web/doc_thumb.jpg"         
    @cloned_object.preview_url = "/user_files/" + current_user.userid + "/templates/" + mytemplate_filename + "/web/doc_preview.jpg"             
    
    @cloned_object.category = @object_to_clone.category
    @cloned_object.subcategory = @object_to_clone.subcategory
    
    @cloned_object.save
 
    new_temp_dir = path + "/" + mytemplate_filename
    FileUtils.mkdir_p(File.dirname(new_temp_dir))   
    puts_message @object_to_clone.path
    puts_message new_temp_dir
    FileUtils.cp_r TEMP_PATH + mytemplate_filename, new_temp_dir  
    #--- delete template's mjob file     
    tmp = new_temp_dir + "/do_job.mjob"
    FileUtils.remove_entry_secure(tmp) if File.exist?(tmp)  
  end


         
end

