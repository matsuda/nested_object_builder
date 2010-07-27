NestedObjectBuilder
===================

## インストール

  ruby script/plugin install git://github.com/matsuda/nested_object_builder.git

## 使い方

### migration

db/migrate/20100722131500_create_job_subjects.rb

<pre>
class CreateJobSubjects < ActiveRecord::Migration
  def self.up
    create_table :job_subjects do |t|
      t.integer :job_id, :null => false
      t.integer :subject_id, :null => false
      t.text    :freetext

      t.timestamps
    end
    add_index :job_subjects, :job_id
  end

  def self.down
    drop_table :job_subjects
  end
end
</pre>

### model

app/models/job.rb

<pre>
class Job < ActiveRecord::Base
  has_many  :job_subjects, :order => :subject_id,
            :builder => :subjects, :builder_include => :subject
  has_many  :subjects, :through => :job_subjects, :order => :subject_id
end
</pre>

app/models/job_subject_.rb

<pre>
class JobSubject < ActiveRecord::Base
  belongs_to :job
  belongs_to :subject

  validates_presence_of :freetext, :if => Proc.new{ |record| record.subject_id == 24 }

  def name
    self.subject.name
  end

  def name_with_freetext
    str = ''
    str << self.name
    str << "（#{self.freetext}）" if self.freetext.present?
    str
  end
end
</pre>

### controller

<pre>
class SubjectsController < ApplicationController

  def new
    @job = Job.new
    @job.job_subjects.builds
  end

  def confirm
    @job = Job.new(params[:job])

    unless @job.valid?
      @job.job_subjects.builds
      render :new and return
    end
  end

  def create
    @job = Job.new(params[:job])

    if params[:back].present?
      @job.job_subjects.builds
      render :new and return
    end

    if @job.save
      redirect_to job_path(@classroom, @job), :notice => '募集要項を編集しました。'
    else
      @job.job_subjects.builds
      render :new
    end
  end
</pre>

### view

app/views/subjects/new.html.erb

<pre>
  === snip ====
  <%- form.fields_for :job_subjects do |nested_form| -%>
    <%= nested_form.nested_fields_check_box(:subject, :subject_id) %>
    <%- if nested_form.object.subject_id == Subject.name_options.size -%>
      <%= nested_form.text_field :freetext, :size => 20 %>
    <%- end -%>
  <%- end -%>
  === snip ====
</pre>

app/views/subjects/confirm.html.erb

<pre>
  === snip ====
  <%- form.fields_for :job_subjects do |nested_form| -%>
    <%= nested_form.nested_fields_hidden_field :subject_id %>
    <%- if nested_form.object.subject_id == Subject.name_options.size -%>
      <%= nested_form.hidden_field :freetext %>
    <%- end -%>
  <%- end -%>
  === snip ====
</pre>

app/views/subjects/show.html.erb

<pre>
  === snip ====
  <%- if params[:action] =~ /confirm/ -%>
    <%=h @job.job_subjects.builder_expectants.map(&:name_with_freetext).join(', ') %>
  <%- else -%>
    <%=h @job.job_subjects.map(&:name_with_freetext).join(', ') %>
  <%- end -%>
  === snip ====
</pre>


Copyright (c) 2010 kosukematsuda(at)gmail.com, released under the MIT license
