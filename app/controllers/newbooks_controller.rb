# encoding: utf-8

class NewbooksController < ApplicationController
  before_filter :authenticate_user!

  def index
    @menu = "myarticles"
    @structures = Book_basic.all()

    render 'newbook'  
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
    @article = Article.get(params[:id])

    respond_to do |format|
      if @article.update(params[:article])
        flash[:notice] = 'Article was successfully updated.'
        format.html { redirect_to(@article) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
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
  
def test

  basic = params[:basic]

  level1 = params[:level1]
  level2 = params[:level2]
  level3 = params[:level3]    
  level4 = params[:level4]    

  level1_up = params[:level1_up]  
  level2_up = params[:level2_up]  
  level3_up = params[:level3_up]      
  level4_up = params[:level4_up]      

  level1_self = params[:level1_self]  
  level2_self = params[:level2_self]  
  level3_self = params[:level3_self]      
  level4_self = params[:level4_self]      

  book_title = basic[0]
  book_inner_cover = basic[1]
  book_index = basic[2]
  book_prologue = basic[3]
  
  @new_book = Book_basic.new()
  @new_book.title = book_title
  @new_book.inner_cover = book_inner_cover
  @new_book.index_title = book_index
  @new_book.prologue_title = book_prologue
  @new_book.user_id = current_user.id

  if @new_book.save
      book_basic_id = @new_book.id
  end
  
  puts_message book_basic_id.to_s
  
  basic.each do |b|
    puts b
  end
  
  if !level1.nil?
  
    if level1.length ==  0
      puts "it's nil!!!!"
    else
      i = 0
      while (i < level1.length) # level1 Loop ===============================================================
        j = 0        
        new_article = Book_article.new()
        new_article.book_basic_id = @new_book.id
        new_article.user_id = current_user.id
        new_article.title = level1[i].to_s
        new_article.upper_level = 0
        new_article.self_level = 1
        new_article.order = i + 1
        new_article.save
        level1_id = new_article.id

        if !level2.nil?
          while (j < level2.length) # level2 Loop ==========================================================
            k = 0
            if level1_self[i]  == level2_up[j]
              new_article = Book_article.new()
              new_article.book_basic_id = @new_book.id   
              new_article.user_id = current_user.id                         
              new_article.title = level2[i].to_s
              new_article.upper_level = level1_id
              new_article.self_level = 2
              new_article.order = j + 1
              new_article.save
              level2_id = new_article.id
              
              if !level3.nil?
                while (k < level3.length) # level3 Loop ====================================================
                  if level2_self[j] == level3_up[k]
                    new_article = Book_article.new()
                    new_article.user_id = current_user.id                    
                    new_article.book_basic_id = @new_book.id                    
                    new_article.title = level3[i].to_s
                    new_article.upper_level = level2_id
                    new_article.self_level = 3
                    new_article.order = k + 1
                    new_article.save
                    level3_id = new_article.id

                    if !level4.nil?
                      l = 0
                      while (l < level4.length) # level4 Loop =============================================
                        if level3_self[k] == level4_up[l]
                          new_article = Book_article.new()
                          new_article.user_id = current_user.id                          
                          new_article.book_basic_id = @new_book.id                          
                          new_article.title = level4[i].to_s
                          new_article.upper_level = level3_id
                          new_article.self_level = 4
                          new_article.order = l + 1
                          new_article.save
                        end
                        l += 1
                      end # level4 Loop ====================================================================
                    end
                    
                  end
                  k += 1
                end # level3 Loop ==========================================================================
              end
            end
            j += 1
          end # level2 Loop ================================================================================
        end
        
        i += 1
      end # level1 Loop ====================================================================================   
    end
  end
  
  @book_id = book_basic_id
  @book_list = Book_basic.all(:user_id => current_user.id)
  render :partial => "result", :object => @book_id

 # render :update do |page|
 #   page.replace_html 'result', "result"
 # end
  
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
  
  if @book_basic.destroy 
    if @book_articles.destroy
      @book_list = Book_basic.all(:user_id => current_user.id)

      tmp_msg = "on deleting "+@book_basic.title+"'s articles: total "+@book_articles.count.to_s+" articles ..."    
      puts_message tmp_msg
      
    else
      puts_message "error occured on progress of deleting Book_articles table..."        
    end

    render :partial => "new_book_list", :object => @book_list, :object => @need_reload
    # render 'bookarticle'
  else
    puts_message "error occured on progress of deleting Book_basic table..."
  end
end

end
