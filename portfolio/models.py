"""
Portfolio Models

This module contains all the database models for the portfolio website,
including Project, Testimonial, Skill, and TimelineEvent models.
"""

from django.db import models
from django.urls import reverse
from django.utils.text import slugify


class Project(models.Model):
    """
    Main Project model for portfolio showcases.
    
    Stores all information about projects including title, description,
    tech stack, images, and links.
    """
    
    CATEGORY_CHOICES = [
        ('frontend', 'Frontend'),
        ('backend', 'Backend'),
        ('fullstack', 'Fullstack'),
        ('design', 'Design'),
        ('mobile', 'Mobile'),
    ]
    
    title = models.CharField(
        max_length=100,
        verbose_name='Titolo',
        help_text='Nome del progetto (max 100 caratteri)'
    )
    slug = models.SlugField(
        unique=True,
        blank=True,
        verbose_name='Slug URL',
        help_text='Generato automaticamente dal titolo'
    )
    description = models.TextField(
        verbose_name='Descrizione breve',
        help_text='Descrizione breve del progetto (max 50 parole consigliato)'
    )
    long_description = models.TextField(
        blank=True,
        verbose_name='Descrizione dettagliata',
        help_text='Descrizione estesa per la pagina dettaglio (case study)'
    )
    challenge = models.TextField(
        blank=True,
        verbose_name='La sfida',
        help_text='Quale problema doveva risolvere il progetto?'
    )
    solution = models.TextField(
        blank=True,
        verbose_name='La soluzione',
        help_text='Come hai risolto il problema?'
    )
    results = models.TextField(
        blank=True,
        verbose_name='I risultati',
        help_text='Quali risultati ha ottenuto il progetto?'
    )
    image_thumbnail = models.ImageField(
        upload_to='projects/thumbnails/',
        verbose_name='Immagine thumbnail',
        help_text='Immagine principale del progetto (ratio 16:9 consigliato)'
    )
    image_hero = models.ImageField(
        upload_to='projects/heroes/',
        blank=True,
        null=True,
        verbose_name='Immagine hero',
        help_text='Immagine grande per la pagina dettaglio'
    )
    gallery = models.JSONField(
        default=list,
        blank=True,
        verbose_name='Galleria immagini',
        help_text='Lista di URL immagini aggiuntive (JSON array)'
    )
    tech_stack = models.JSONField(
        default=list,
        verbose_name='Tech Stack',
        help_text='Lista tecnologie usate (es: ["Python", "Django", "PostgreSQL"])'
    )
    external_url = models.URLField(
        blank=True,
        verbose_name='URL Progetto',
        help_text='Link al sito live del progetto'
    )
    github_url = models.URLField(
        blank=True,
        verbose_name='URL GitHub',
        help_text='Link al repository GitHub'
    )
    featured = models.BooleanField(
        default=False,
        verbose_name='In evidenza',
        help_text='Mostra questo progetto in evidenza nella homepage'
    )
    category = models.CharField(
        max_length=20,
        choices=CATEGORY_CHOICES,
        default='fullstack',
        verbose_name='Categoria'
    )
    order = models.PositiveIntegerField(
        default=0,
        verbose_name='Ordine',
        help_text='Ordine di visualizzazione (numero più basso = prima posizione)'
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Data creazione'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Ultimo aggiornamento'
    )
    is_visible = models.BooleanField(
        default=True,
        verbose_name='Visibile',
        help_text='Rendi il progetto visibile nel portfolio'
    )
    
    class Meta:
        verbose_name = 'Progetto'
        verbose_name_plural = 'Progetti'
        ordering = ['order', '-created_at']
    
    def __str__(self):
        return self.title
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
            # Ensure unique slug
            original_slug = self.slug
            counter = 1
            while Project.objects.filter(slug=self.slug).exclude(pk=self.pk).exists():
                self.slug = f"{original_slug}-{counter}"
                counter += 1
        super().save(*args, **kwargs)
    
    def get_absolute_url(self):
        return reverse('portfolio:project_detail', kwargs={'slug': self.slug})
    
    @property
    def tech_stack_list(self):
        """Return tech stack as list even if stored as string."""
        if isinstance(self.tech_stack, list):
            return self.tech_stack
        if isinstance(self.tech_stack, str):
            return [t.strip() for t in self.tech_stack.split(',')]
        return []


class Testimonial(models.Model):
    """
    Testimonial model for client/collaborator reviews.
    """
    
    name = models.CharField(
        max_length=100,
        verbose_name='Nome'
    )
    role = models.CharField(
        max_length=100,
        verbose_name='Ruolo/Azienda'
    )
    quote = models.TextField(
        verbose_name='Citazione',
        help_text='La testimonianza del cliente'
    )
    photo = models.ImageField(
        upload_to='testimonials/',
        blank=True,
        null=True,
        verbose_name='Foto profilo'
    )
    project = models.ForeignKey(
        Project,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='testimonials',
        verbose_name='Progetto correlato'
    )
    order = models.PositiveIntegerField(
        default=0,
        verbose_name='Ordine'
    )
    is_visible = models.BooleanField(
        default=True,
        verbose_name='Visibile'
    )
    created_at = models.DateTimeField(
        auto_now_add=True
    )
    
    class Meta:
        verbose_name = 'Testimonianza'
        verbose_name_plural = 'Testimonianze'
        ordering = ['order', '-created_at']
    
    def __str__(self):
        return f"{self.name} - {self.role}"


class Skill(models.Model):
    """
    Skill model for skills matrix section.
    """
    
    CATEGORY_CHOICES = [
        ('frontend', 'Frontend'),
        ('backend', 'Backend'),
        ('tools', 'Tools & DevOps'),
        ('soft', 'Soft Skills'),
    ]
    
    name = models.CharField(
        max_length=50,
        verbose_name='Nome skill'
    )
    category = models.CharField(
        max_length=20,
        choices=CATEGORY_CHOICES,
        verbose_name='Categoria'
    )
    icon = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='Classe icona',
        help_text='Classe CSS per l\'icona (es: fab fa-python)'
    )
    years_experience = models.PositiveSmallIntegerField(
        default=1,
        verbose_name='Anni esperienza'
    )
    proficiency = models.PositiveSmallIntegerField(
        default=80,
        verbose_name='Livello (%)',
        help_text='Livello di competenza da 0 a 100'
    )
    related_projects = models.ManyToManyField(
        Project,
        blank=True,
        related_name='skills',
        verbose_name='Progetti correlati'
    )
    order = models.PositiveIntegerField(
        default=0,
        verbose_name='Ordine'
    )
    is_visible = models.BooleanField(
        default=True,
        verbose_name='Visibile'
    )
    
    class Meta:
        verbose_name = 'Competenza'
        verbose_name_plural = 'Competenze'
        ordering = ['category', 'order', 'name']
    
    def __str__(self):
        return f"{self.name} ({self.get_category_display()})"


class TimelineEvent(models.Model):
    """
    Timeline event model for career/journey section.
    """
    
    title = models.CharField(
        max_length=100,
        verbose_name='Titolo'
    )
    description = models.TextField(
        verbose_name='Descrizione'
    )
    tech_stack = models.JSONField(
        default=list,
        blank=True,
        verbose_name='Tech Stack',
        help_text='Tecnologie usate in questo periodo'
    )
    year = models.CharField(
        max_length=20,
        verbose_name='Anno/Periodo',
        help_text='Es: "2020", "2019-2021", "Presente"'
    )
    icon = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='Icona',
        help_text='Classe CSS icona'
    )
    color = models.CharField(
        max_length=20,
        default='#00d9ff',
        verbose_name='Colore',
        help_text='Colore del punto timeline (hex)'
    )
    order = models.PositiveIntegerField(
        default=0,
        verbose_name='Ordine'
    )
    is_visible = models.BooleanField(
        default=True,
        verbose_name='Visibile'
    )
    
    class Meta:
        verbose_name = 'Evento Timeline'
        verbose_name_plural = 'Eventi Timeline'
        ordering = ['order']
    
    def __str__(self):
        return f"{self.year} - {self.title}"


class SiteSettings(models.Model):
    """
    Singleton model for site-wide settings.
    Only one instance should exist.
    """
    
    site_name = models.CharField(
        max_length=100,
        default='Luigi Portfolio',
        verbose_name='Nome sito'
    )
    tagline = models.CharField(
        max_length=200,
        default='Web Developer',
        verbose_name='Tagline'
    )
    hero_title = models.CharField(
        max_length=200,
        default='Creo esperienze digitali',
        verbose_name='Titolo Hero'
    )
    hero_subtitle = models.TextField(
        default='Web Developer specializzato nella creazione di siti web moderni, performanti e user-friendly.',
        verbose_name='Sottotitolo Hero'
    )
    about_text = models.TextField(
        blank=True,
        verbose_name='Testo "Chi sono"'
    )
    profile_image = models.ImageField(
        upload_to='site/',
        blank=True,
        null=True,
        verbose_name='Foto profilo'
    )
    email = models.EmailField(
        blank=True,
        verbose_name='Email'
    )
    phone = models.CharField(
        max_length=20,
        blank=True,
        verbose_name='Telefono'
    )
    location = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Località'
    )
    github_url = models.URLField(
        blank=True,
        verbose_name='GitHub URL'
    )
    linkedin_url = models.URLField(
        blank=True,
        verbose_name='LinkedIn URL'
    )
    twitter_url = models.URLField(
        blank=True,
        verbose_name='Twitter URL'
    )
    cv_file = models.FileField(
        upload_to='files/',
        blank=True,
        null=True,
        verbose_name='CV PDF'
    )
    
    # Stats
    projects_completed = models.PositiveIntegerField(
        default=15,
        verbose_name='Progetti completati'
    )
    sites_live = models.PositiveIntegerField(
        default=10,
        verbose_name='Siti online'
    )
    years_experience = models.PositiveIntegerField(
        default=3,
        verbose_name='Anni esperienza'
    )
    happy_clients = models.PositiveIntegerField(
        default=12,
        verbose_name='Clienti soddisfatti'
    )
    
    class Meta:
        verbose_name = 'Impostazioni Sito'
        verbose_name_plural = 'Impostazioni Sito'
    
    def __str__(self):
        return 'Impostazioni Sito'
    
    def save(self, *args, **kwargs):
        # Ensure only one instance exists
        self.pk = 1
        super().save(*args, **kwargs)
    
    @classmethod
    def get_settings(cls):
        """Get or create the site settings instance."""
        obj, created = cls.objects.get_or_create(pk=1)
        return obj


class ContactMessage(models.Model):
    """
    Model to store contact form submissions.
    """
    
    name = models.CharField(
        max_length=100,
        verbose_name='Nome'
    )
    email = models.EmailField(
        verbose_name='Email'
    )
    subject = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Oggetto'
    )
    message = models.TextField(
        verbose_name='Messaggio'
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Data invio'
    )
    is_read = models.BooleanField(
        default=False,
        verbose_name='Letto'
    )
    
    class Meta:
        verbose_name = 'Messaggio'
        verbose_name_plural = 'Messaggi'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} - {self.subject or 'Nessun oggetto'}"
