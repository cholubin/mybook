# encoding: utf-8

class BookarticlesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @menu = "myarticles"
    book_id = params[:book_id]
    
    if !book_id.nil?
      @book_basic = Book_basic.get(book_id.to_i)
    else
      
    end
    render 'bookarticle'  
  end
  
  
  # GET /articles/1
  # GET /articles/1.xml
  def show
    @article = Article.get(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @article }
    end
  end

  # GET /articles/faq_new
  # GET /articles/faq_new.xml
  def new
    @article = Article.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @article }
    end
  end
  
  # GET /articles/faq_new
  # GET /articles/faq_new.xml
  def faq_new
    @article = Article.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @article }
    end
  end
  
  def store_dir   
    dir = "#{RAILS_ROOT}/public/user_files/images/"
    FileUtils.mkdir_p dir if not File.exist?(dir)
    FileUtils.chmod 0777, dir
    return dir 
    # "#{RAILS_ROOT}/public/user_files/images/"
  end
  
  # GET /articles/1/edit
  def edit
    @article = Article.get(params[:id])
  end

  # POST /articles
  # POST /articles.xml
  def create
    
    @article = Article.new(params[:article])
    
    # 이미지 업로드 처리 ===============================================================================
    if params[:article][:image_file] != nil
       
      @article.image_file = params[:article][:image_file]      
      @temp_filename = sanitize_filename(params[:article][:image_file].original_filename)
      
      # 중복파일명 처리 ===============================================================================
      while File.exist?(IMAGE_PATH + @temp_filename) 
        @temp_filename = @temp_filename.gsub(File.extname(@temp_filename),"") + "_1" + File.extname(@temp_filename)
        @article.image_filename = @temp_filename
        # puts @article.image_filename
      end 
      @article.image_filename = @temp_filename
       # 중복파일명 처리 ===============================================================================
      
      @article.image_filename_encoded = @article.image_file.filename
    
    end 
          
  respond_to do |format|
      if @article.save  
        
        # image filename renaming ======================================================================
        file_name = @article.image_filename_encoded

        if file_name
         if  File.exist?(IMAGE_PATH + file_name)
          	File.rename IMAGE_PATH + file_name, IMAGE_PATH  + @article.image_filename #original file
          	File.rename IMAGE_PATH + "t_" + file_name, IMAGE_PATH + "t_" + @article.image_filename #thumbnail file
          end
        end      
        # image filename renaming ======================================================================
        
        flash[:notice] = 'Article was successfully created.'
        format.html { redirect_to(@article) }
        format.xml  { render :xml => @article, :status => :created, :location => @article }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
    end
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
    @book_basic = Book_basic.get(params[:book_id].to_i)
    @book_articles = Book_article.all(:book_basic_id => params[:id].to_i)
    
    if @book_basic.destroy and @book_articles.destroy
      @book_list = Book_basic.all(:user_id => current_user.id)
      render :partial => "new_book_list", :object => @book_list
    else
      puts_message "error occured!"
    end
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
