"""
Sitemap Configuration

Sitemaps for SEO optimization.
"""

from django.contrib.sitemaps import Sitemap
from django.urls import reverse

from .models import Project


class StaticViewSitemap(Sitemap):
    """Sitemap for static pages."""
    
    priority = 1.0
    changefreq = 'weekly'
    
    def items(self):
        return ['portfolio:index', 'portfolio:projects_list']
    
    def location(self, item):
        return reverse(item)


class ProjectSitemap(Sitemap):
    """Sitemap for project detail pages."""
    
    priority = 0.8
    changefreq = 'monthly'
    
    def items(self):
        return Project.objects.filter(is_visible=True)
    
    def lastmod(self, obj):
        return obj.updated_at
    
    def location(self, obj):
        return obj.get_absolute_url()
