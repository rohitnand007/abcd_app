module TestResultsHelper

  def bread_crumb_test_reports_page
    if current_et
      content_tag(:ul,
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                  content_tag(:li,"#{link_to  'My Assessments', assessments_path}".html_safe) +
                  content_tag(:li,"#{link_to  'TestReports', '#',{:class=>'current'}}".html_safe) )
    else
      content_tag(:ul,
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                  content_tag(:li,"#{link_to  'Assessments', assessments_path}".html_safe) +
                  content_tag(:li,"#{link_to  'TestReports', '#',{:class=>'current'}}".html_safe) )
    end
  end

  def bread_crumb_test_evaluate_page
    if current_et
      content_tag(:ul,
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                  content_tag(:li,"#{link_to  'My Assessments', assessments_path}".html_safe) +
                  content_tag(:li,"#{link_to  'Test Evaluate', '#',{:class=>'current'}}".html_safe) )
    else
      content_tag(:ul,
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                  content_tag(:li,"#{link_to  'Assessments', assessments_path}".html_safe) +
                  content_tag(:li,"#{link_to  'Test Evaluate', '#',{:class=>'current'}}".html_safe) )
    end
  end
end
